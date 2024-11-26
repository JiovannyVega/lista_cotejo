import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'group_screen.dart';
import 'settings_screen.dart'; // Add this line to import the SettingsScreen class

class HomeScreen extends StatefulWidget {
  final Future<Database> database;
  final String username;

  const HomeScreen({super.key, required this.database, required this.username});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<String> _getMaestroName() async {
    final db = await widget.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT Maestro.nombre
      FROM Usuario
      JOIN Maestro ON Usuario.id_maestro = Maestro.id_maestro
      WHERE Usuario.username = ?
    ''', [widget.username]);

    if (result.isNotEmpty) {
      return result.first['nombre'];
    } else {
      return 'Maestro';
    }
  }

  Future<List<Map<String, dynamic>>> _getGrupos() async {
    final db = await widget.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT Grupo.clave, Materia.nombre AS materia
      FROM Grupo
      JOIN Materia ON Grupo.id_materia = Materia.id_materia
      JOIN Usuario ON Grupo.id_maestro = Usuario.id_maestro
      WHERE Usuario.username = ?
    ''', [widget.username]);

    return result;
  }

  void _showAddGroupDialog(BuildContext context) {
    final claveController = TextEditingController();
    String? selectedMateria;

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getMaterias(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final materias = snapshot.data ?? [];
              return AlertDialog(
                title: const Text('Agregar Grupo'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: claveController,
                      decoration: const InputDecoration(labelText: 'Clave'),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedMateria,
                      items: materias.map((materia) {
                        return DropdownMenuItem<String>(
                          value: materia['id_materia'].toString(),
                          child: Text(materia['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedMateria = value;
                      },
                      decoration: const InputDecoration(labelText: 'Materia'),
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
                      final db = await widget.database;
                      final idMaestroResult = await db.rawQuery('''
                        SELECT id_maestro FROM Usuario WHERE username = ?
                      ''', [widget.username]);

                      if (idMaestroResult.isNotEmpty) {
                        final idMaestro = idMaestroResult.first['id_maestro'];
                        await db.insert(
                          'Grupo',
                          {
                            'clave': claveController.text,
                            'id_maestro': idMaestro,
                            'id_materia': int.parse(selectedMateria!),
                          },
                        );
                        setState(() {}); // Actualizar la lista de grupos
                      }

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

  Future<List<Map<String, dynamic>>> _getMaterias() async {
    final db = await widget.database;
    return await db.query('Materia');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    database: widget.database,
                    username: widget.username,
                  ),
                ),
              );
              if (result == true) {
                setState(() {}); // Refrescar la pantalla principal
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getMaestroName(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final maestroName = snapshot.data ?? 'Maestro';
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Hola, $maestroName!',
                      style: const TextStyle(fontSize: 24)),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child:
                      Text('Lista de Grupos', style: TextStyle(fontSize: 20)),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getGrupos(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        final grupos = snapshot.data ?? [];
                        if (grupos.isEmpty) {
                          return const Center(
                            child: Text(
                              'No tienes grupos. Para crear un grupo, presiona el botón "+" en la esquina inferior derecha.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        } else {
                          return ListView.builder(
                            itemCount: grupos.length,
                            itemBuilder: (context, index) {
                              final grupo = grupos[index];
                              return ListTile(
                                title: Text(grupo['clave']),
                                subtitle: Text(grupo['materia']),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GroupScreen(
                                        clave: grupo['clave'],
                                        materia: grupo['materia'],
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
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGroupDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
