import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

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
    final _claveController = TextEditingController();
    String? _selectedMateria;

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getMaterias(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final materias = snapshot.data ?? [];
              return AlertDialog(
                title: Text('Agregar Grupo'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _claveController,
                      decoration: InputDecoration(labelText: 'Clave'),
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedMateria,
                      items: materias.map((materia) {
                        return DropdownMenuItem<String>(
                          value: materia['id_materia'].toString(),
                          child: Text(materia['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        _selectedMateria = value;
                      },
                      decoration: InputDecoration(labelText: 'Materia'),
                    ),
                  ],
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
                      final db = await widget.database;
                      final idMaestroResult = await db.rawQuery('''
                        SELECT id_maestro FROM Usuario WHERE username = ?
                      ''', [widget.username]);

                      if (idMaestroResult.isNotEmpty) {
                        final idMaestro = idMaestroResult.first['id_maestro'];
                        await db.insert(
                          'Grupo',
                          {
                            'clave': _claveController.text,
                            'id_maestro': idMaestro,
                            'id_materia': int.parse(_selectedMateria!),
                          },
                        );
                        setState(() {}); // Actualizar la lista de grupos
                      }

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

  Future<List<Map<String, dynamic>>> _getMaterias() async {
    final db = await widget.database;
    return await db.query('Materia');
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
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Hola, $maestroName!',
                      style: TextStyle(fontSize: 24)),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getGrupos(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        final grupos = snapshot.data ?? [];
                        return ListView.builder(
                          itemCount: grupos.length,
                          itemBuilder: (context, index) {
                            final grupo = grupos[index];
                            return ListTile(
                              title: Text(grupo['clave']),
                              subtitle: Text(grupo['materia']),
                            );
                          },
                        );
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
        child: Icon(Icons.add),
      ),
    );
  }
}
