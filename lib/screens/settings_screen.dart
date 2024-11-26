import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'students_screen.dart'; // Importar la nueva pantalla de alumnos

class SettingsScreen extends StatelessWidget {
  final Future<Database> database;
  final String username;

  const SettingsScreen(
      {super.key, required this.database, required this.username});

  void _showEditUserDialog(BuildContext context) async {
    final db = await database;
    final List<Map<String, dynamic>> userResult = await db.query(
      'Usuario',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (userResult.isNotEmpty) {
      final user = userResult.first;
      final nameController = TextEditingController(text: user['username']);
      final passwordController = TextEditingController(text: user['password']);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Modificar Usuario'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
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
                      passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Todos los campos deben estar llenos')),
                    );
                    return;
                  }
                  await db.update(
                    'Usuario',
                    {
                      'username': nameController.text,
                      'password': passwordController.text,
                    },
                    where: 'username = ?',
                    whereArgs: [username],
                  );
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true); // Indicar que hubo cambios
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showEditProfileDialog(BuildContext context) async {
    final db = await database;
    final List<Map<String, dynamic>> userResult = await db.query(
      'Usuario',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (userResult.isNotEmpty) {
      final user = userResult.first;
      final List<Map<String, dynamic>> maestroResult = await db.query(
        'Maestro',
        where: 'id_maestro = ?',
        whereArgs: [user['id_maestro']],
      );

      if (maestroResult.isNotEmpty) {
        final maestro = maestroResult.first;
        final nameController = TextEditingController(text: maestro['nombre']);
        final lastNameController =
            TextEditingController(text: maestro['apellido']);
        final careerController =
            TextEditingController(text: maestro['carrera']);

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Modificar Perfil'),
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
                        careerController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Todos los campos deben estar llenos')),
                      );
                      return;
                    }
                    await db.update(
                      'Maestro',
                      {
                        'nombre': nameController.text,
                        'apellido': lastNameController.text,
                        'carrera': careerController.text,
                      },
                      where: 'id_maestro = ?',
                      whereArgs: [user['id_maestro']],
                    );
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(true); // Indicar que hubo cambios
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showEditUserDialog(context),
              child: const Text('Modificar Usuario'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showEditProfileDialog(context),
              child: const Text('Modificar Perfil'),
            ),
            const SizedBox(height: 20), // Espacio entre botones
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentsScreen(database: database),
                  ),
                );
              },
              child: const Text('Ver Alumnos'),
            ),
          ],
        ),
      ),
    );
  }
}
