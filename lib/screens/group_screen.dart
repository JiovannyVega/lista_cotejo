import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:table_calendar/table_calendar.dart';
import 'activity_detail_screen.dart';
import 'alumno_detail_screen.dart';
import 'pass_attendance_screen.dart'; // Importar la nueva pantalla

class GroupScreen extends StatefulWidget {
  final String clave;
  final String materia;

  const GroupScreen({super.key, required this.clave, required this.materia});

  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nombreActividadController = TextEditingController();
  final _descActividadController = TextEditingController();
  final _fechaActividadController = TextEditingController();
  final _ponderacionActividadController = TextEditingController();
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this); // Cambiar a 3 pestañas
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final actividades = await _getActividades();
    setState(() {
      _events = {};
      for (var actividad in actividades) {
        final date = DateTime.parse(actividad['fecha']);
        final eventDate = DateTime(date.year, date.month, date.day);
        if (_events[eventDate] == null) {
          _events[eventDate] = [];
        }
        _events[eventDate]!.add(actividad);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getActividades() async {
    final db = await openDatabase('lista_cotejo.db');
    return await db
        .query('Actividad', where: 'id_grupo = ?', whereArgs: [widget.clave]);
  }

  Future<List<Map<String, dynamic>>> _getAlumnos() async {
    final db = await openDatabase('lista_cotejo.db');
    return await db.rawQuery('''
      SELECT Alumno.id_alumno, Alumno.nombre, Alumno.apellido
      FROM Folio
      JOIN Alumno ON Folio.id_alumno = Alumno.id_alumno
      WHERE Folio.id_grupo = ?
      ORDER BY Alumno.nombre, Alumno.apellido
    ''', [widget.clave]);
  }

  Future<List<Map<String, dynamic>>> _getAvailableAlumnos() async {
    final db = await openDatabase('lista_cotejo.db');
    return await db.rawQuery('''
      SELECT Alumno.id_alumno, Alumno.nombre, Alumno.apellido
      FROM Alumno
      WHERE Alumno.id_alumno NOT IN (
        SELECT id_alumno
        FROM Folio
        WHERE id_grupo = ?
      )
      ORDER BY Alumno.nombre, Alumno.apellido
    ''', [widget.clave]);
  }

  Future<void> _deleteAlumno(int idAlumno) async {
    final db = await openDatabase('lista_cotejo.db');
    await db.delete('Folio',
        where: 'id_alumno = ? AND id_grupo = ?',
        whereArgs: [idAlumno, widget.clave]);
    setState(() {}); // Actualizar la lista de alumnos
  }

  void _showDeleteConfirmationDialog(BuildContext context, int idAlumno) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
              '¿Estás seguro de que deseas eliminar a esta persona del grupo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteAlumno(idAlumno);
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F1E57), // Color guindo
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Actividad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreActividadController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _descActividadController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: _fechaActividadController,
                decoration: const InputDecoration(labelText: 'Fecha'),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _fechaActividadController.text =
                          pickedDate.toString().split(' ')[0];
                    });
                  }
                },
              ),
              TextField(
                controller: _ponderacionActividadController,
                decoration: const InputDecoration(labelText: 'Ponderación'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearActivityForm();
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nombreActividadController.text.isEmpty ||
                    _descActividadController.text.isEmpty ||
                    _fechaActividadController.text.isEmpty ||
                    _ponderacionActividadController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, llena todos los campos')),
                  );
                  return;
                }
                final db = await openDatabase('lista_cotejo.db');
                await db.insert(
                  'Actividad',
                  {
                    'nombre': _nombreActividadController.text,
                    'desc': _descActividadController.text,
                    'fecha': _fechaActividadController.text,
                    'ponderacion': _ponderacionActividadController.text,
                    'id_grupo': widget.clave,
                  },
                );
                await _loadEvents(); // Recargar eventos
                setState(() {}); // Actualizar la lista de actividades
                _clearActivityForm();
                Navigator.of(context).pop();
              },
              child: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F1E57), // Color guindo
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddAlumnoDialog(BuildContext context) {
    String? selectedAlumno;

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAvailableAlumnos(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final alumnos = snapshot.data ?? [];
              return AlertDialog(
                title: const Text('Agregar Alumno'),
                content: DropdownButtonFormField<String>(
                  value: selectedAlumno,
                  items: alumnos.map((alumno) {
                    return DropdownMenuItem<String>(
                      value: alumno['id_alumno'].toString(),
                      child: Text('${alumno['nombre']} ${alumno['apellido']}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedAlumno = value;
                  },
                  decoration: const InputDecoration(labelText: 'Alumno'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedAlumno == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Por favor, selecciona un alumno')),
                        );
                        return;
                      }
                      final db = await openDatabase('lista_cotejo.db');
                      await db.insert(
                        'Folio',
                        {
                          'id_grupo': widget.clave,
                          'id_alumno': int.parse(selectedAlumno!),
                        },
                      );
                      setState(() {}); // Actualizar la lista de alumnos
                      Navigator.of(context).pop();
                    },
                    child: const Text('Agregar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F1E57), // Color guindo
                    ),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  void _clearActivityForm() {
    _nombreActividadController.clear();
    _descActividadController.clear();
    _fechaActividadController.clear();
    _ponderacionActividadController.clear();
  }

  void _showActivitiesForDay(BuildContext context, DateTime day) {
    final eventDate = DateTime(day.year, day.month, day.day);
    final activities = _events[eventDate] ?? [];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              'Actividades para ${eventDate.toLocal().toString().split(' ')[0]}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: activities.map<Widget>((actividad) {
              return ListTile(
                title: Text(actividad['nombre']),
                subtitle: Text(actividad['desc']),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToPassAttendanceScreen(context, day);
              },
              child: const Text('Pasar Lista'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F1E57), // Color guindo
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPassAttendanceScreen(BuildContext context, DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PassAttendanceScreen(clave: widget.clave, date: date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Grupo: ${widget.clave} - ${widget.materia}'),
        ),
        backgroundColor: const Color(0xFF924e7d), // Update primary color
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Actividades'),
            Tab(text: 'Personas'),
            Tab(text: 'Calendario'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Stack(
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getActividades(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final actividades = snapshot.data ?? [];
                    if (actividades.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay actividades. Para agregar una actividad, presiona el botón "+" en la esquina inferior derecha.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        itemCount: actividades.length,
                        itemBuilder: (context, index) {
                          final actividad = actividades[index];
                          return ListTile(
                            title: Text(actividad['nombre']),
                            subtitle: Text(actividad['fecha']),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActivityDetailScreen(
                                    actividad: actividad,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }
                  }
                },
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () => _showAddActivityDialog(context),
                  child: const Icon(Icons.add),
                  backgroundColor:
                      const Color(0xFF924e7d), // Update primary color
                ),
              ),
            ],
          ),
          Stack(
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getAlumnos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final alumnos = snapshot.data ?? [];
                    if (alumnos.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay alumnos inscritos en este grupo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        itemCount: alumnos.length,
                        itemBuilder: (context, index) {
                          final alumno = alumnos[index];
                          return ListTile(
                            title: Text(
                                '${alumno['nombre']} ${alumno['apellido']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _showDeleteConfirmationDialog(
                                  context, alumno['id_alumno']),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AlumnoDetailScreen(
                                    idAlumno: alumno['id_alumno'],
                                    nombre: alumno['nombre'],
                                    apellido: alumno['apellido'],
                                    idGrupo: widget.clave,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }
                  }
                },
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () => _showAddAlumnoDialog(context),
                  child: const Icon(Icons.add),
                  backgroundColor:
                      const Color(0xFF924e7d), // Update primary color
                ),
              ),
            ],
          ),
          Stack(
            children: [
              Center(
                child: TableCalendar(
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: DateTime.now(),
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF7F1E57), // Color guindo
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  eventLoader: (day) {
                    final eventDate = DateTime(day.year, day.month, day.day);
                    return _events[eventDate] ?? [];
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {});
                    _showActivitiesForDay(context, selectedDay);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
