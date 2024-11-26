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
    _tabController = TabController(length: 3, vsync: this);
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
      SELECT Alumno.nombre, Alumno.apellido
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

  void _showAddActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar Actividad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreActividadController,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _descActividadController,
                decoration: InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: _fechaActividadController,
                decoration: InputDecoration(labelText: 'Fecha'),
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
                decoration: InputDecoration(labelText: 'Ponderación'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearActivityForm();
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
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
              child: Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _showAddAlumnoDialog(BuildContext context) {
    String? _selectedAlumno;

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAvailableAlumnos(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final alumnos = snapshot.data ?? [];
              return AlertDialog(
                title: Text('Agregar Alumno'),
                content: DropdownButtonFormField<String>(
                  value: _selectedAlumno,
                  items: alumnos.map((alumno) {
                    return DropdownMenuItem<String>(
                      value: alumno['id_alumno'].toString(),
                      child: Text('${alumno['nombre']} ${alumno['apellido']}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _selectedAlumno = value;
                  },
                  decoration: InputDecoration(labelText: 'Alumno'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final db = await openDatabase('lista_cotejo.db');
                      await db.insert(
                        'Folio',
                        {
                          'id_grupo': widget.clave,
                          'id_alumno': int.parse(_selectedAlumno!),
                        },
                      );
                      setState(() {}); // Actualizar la lista de alumnos
                      Navigator.of(context).pop();
                    },
                    child: Text('Agregar'),
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
        title: Text('Grupo: ${widget.clave} - ${widget.materia}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Actividades'),
            Tab(text: 'Personas'),
            Tab(text: 'Ajustes'),
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
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final actividades = snapshot.data ?? [];
                    if (actividades.isEmpty) {
                      return Center(
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
                  child: Icon(Icons.add),
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
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final alumnos = snapshot.data ?? [];
                    if (alumnos.isEmpty) {
                      return Center(
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
                  child: Icon(Icons.add),
                ),
              ),
            ],
          ),
          Center(child: Text('Ajustes')),
        ],
      ),
    );
  }
}
