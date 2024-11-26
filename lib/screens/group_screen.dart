import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // Cambiar a 2 pestañas
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
                setState(() {}); // Actualizar la lista de actividades
                _clearActivityForm();
                Navigator.of(context).pop();
              },
              child: const Text('Agregar'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Grupo: ${widget.clave} - ${widget.materia}'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Actividades'),
            Tab(text: 'Personas'),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
