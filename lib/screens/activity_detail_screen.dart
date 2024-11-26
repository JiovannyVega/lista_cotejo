import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> actividad;

  const ActivityDetailScreen({super.key, required this.actividad});

  @override
  _ActivityDetailScreenState createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  Future<List<Map<String, dynamic>>> _getAlumnosConCalificacion() async {
    final db = await openDatabase('lista_cotejo.db');
    return await db.rawQuery('''
      SELECT Alumno.nombre, Alumno.apellido, IFNULL(Cal_Act.calif, 0) AS calif, Folio.id_folio
      FROM Folio
      JOIN Alumno ON Folio.id_alumno = Alumno.id_alumno
      LEFT JOIN Cal_Act ON Folio.id_folio = Cal_Act.id_folio AND Cal_Act.id_actividad = ?
      WHERE Folio.id_grupo = ?
      ORDER BY Alumno.nombre, Alumno.apellido
    ''', [widget.actividad['id_actividad'], widget.actividad['id_grupo']]);
  }

  void _showEditCalificacionDialog(
      BuildContext context, int idFolio, int ponderacion, int califActual) {
    final _califController =
        TextEditingController(text: califActual.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modificar Calificación'),
          content: TextField(
            controller: _califController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Calificación'),
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
                final nuevaCalif = int.tryParse(_califController.text);
                if (nuevaCalif != null &&
                    nuevaCalif >= 0 &&
                    nuevaCalif <= ponderacion) {
                  final db = await openDatabase('lista_cotejo.db');
                  await db.insert(
                    'Cal_Act',
                    {
                      'calif': nuevaCalif,
                      'id_actividad': widget.actividad['id_actividad'],
                      'id_folio': idFolio,
                    },
                    conflictAlgorithm: ConflictAlgorithm.replace,
                  );
                  Navigator.of(context).pop();
                  setState(() {}); // Actualizar la pantalla
                } else {
                  // Mostrar un mensaje de error si la calificación no es válida
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calificación no válida')),
                  );
                }
              },
              child: const Text('Guardar'),
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
        title: Text(widget.actividad['nombre']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nombre: ${widget.actividad['nombre']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Descripción: ${widget.actividad['desc']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha: ${widget.actividad['fecha']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Ponderación: ${widget.actividad['ponderacion']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Alumnos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _getAlumnosConCalificacion(),
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
                            trailing: Text(
                                'Calificación: ${alumno['calif']} / ${widget.actividad['ponderacion']}'),
                            onTap: () => _showEditCalificacionDialog(
                              context,
                              alumno['id_folio'],
                              widget.actividad['ponderacion'],
                              alumno['calif'],
                            ),
                          );
                        },
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
