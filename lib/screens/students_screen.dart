import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class StudentsScreen extends StatefulWidget {
  final Future<Database> database;

  const StudentsScreen({super.key, required this.database});

  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  Future<List<Map<String, dynamic>>> _getAlumnos() async {
    final db = await widget.database;
    return await db.query('Alumno');
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final lastNameController = TextEditingController();
    final careerController = TextEditingController();
    final yearController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Alumno'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              TextField(
                controller: careerController,
                decoration: const InputDecoration(labelText: 'Carrera'),
              ),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Año de Ingreso'),
              ),
            ],
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
                if (nameController.text.isEmpty ||
                    lastNameController.text.isEmpty ||
                    careerController.text.isEmpty ||
                    yearController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Todos los campos son obligatorios')),
                  );
                  return;
                }
                final db = await widget.database;
                await db.insert(
                  'Alumno',
                  {
                    'nombre': nameController.text,
                    'apellido': lastNameController.text,
                    'carrera': careerController.text,
                    'año_ingreso': yearController.text,
                  },
                );
                setState(() {}); // Actualizar la lista de alumnos
                Navigator.of(context).pop();
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> alumno) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${alumno['nombre']} ${alumno['apellido']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Carrera: ${alumno['carrera']}'),
              Text('Año de Ingreso: ${alumno['año_ingreso']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteStudent(BuildContext context, int idAlumno) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Alumno'),
          content:
              const Text('¿Estás seguro de que deseas eliminar este alumno?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = await widget.database;
                await db.delete(
                  'Alumno',
                  where: 'id_alumno = ?',
                  whereArgs: [idAlumno],
                );
                setState(() {}); // Actualizar la lista de alumnos
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Alumnos'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAlumnos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final alumnos = snapshot.data ?? [];
            if (alumnos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No hay alumnos. Para agregar un alumno, presiona el botón "+" en la esquina inferior derecha.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _showAddStudentDialog(context),
                      child: const Text('Agregar Alumno'),
                    ),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                itemCount: alumnos.length,
                itemBuilder: (context, index) {
                  final alumno = alumnos[index];
                  return ListTile(
                    title: Text('${alumno['nombre']} ${alumno['apellido']}'),
                    subtitle: Text(alumno['carrera']),
                    onTap: () => _showStudentDetails(context, alumno),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          _confirmDeleteStudent(context, alumno['id_alumno']),
                    ),
                  );
                },
              );
            }
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStudentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
