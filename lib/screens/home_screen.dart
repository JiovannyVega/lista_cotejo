import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class HomeScreen extends StatelessWidget {
  final Future<Database> database;
  final String username;

  const HomeScreen({super.key, required this.database, required this.username});

  Future<String> _getMaestroName() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT Maestro.nombre
      FROM Usuario
      JOIN Maestro ON Usuario.id_maestro = Maestro.id_maestro
      WHERE Usuario.username = ?
    ''', [username]);

    if (result.isNotEmpty) {
      return result.first['nombre'];
    } else {
      return 'Maestro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navegar a la pantalla de configuración
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getMaestroName(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final maestroName = snapshot.data ?? 'Maestro';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hola, $maestroName!', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navegar a la pantalla de gestión de alumnos
                    },
                    child: Text('Gestionar Alumnos'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Navegar a la pantalla de gestión de materias
                    },
                    child: Text('Gestionar Materias'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
