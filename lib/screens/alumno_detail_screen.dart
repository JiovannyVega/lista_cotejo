import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class AlumnoDetailScreen extends StatelessWidget {
  final int idAlumno;
  final String nombre;
  final String apellido;
  final String idGrupo;

  const AlumnoDetailScreen({
    super.key,
    required this.idAlumno,
    required this.nombre,
    required this.apellido,
    required this.idGrupo,
  });

  Future<List<Map<String, dynamic>>> _getActividadesConCalificacion() async {
    if (idAlumno <= 0 ||
        nombre.isEmpty ||
        apellido.isEmpty ||
        idGrupo.isEmpty) {
      throw Exception('Todos los campos deben estar llenos y ser válidos.');
    }
    final db = await openDatabase('lista_cotejo.db');
    return await db.rawQuery('''
      SELECT Actividad.nombre, Actividad.ponderacion, IFNULL(Cal_Act.calif, 0) AS calif
      FROM Actividad
      LEFT JOIN Cal_Act ON Actividad.id_actividad = Cal_Act.id_actividad
      LEFT JOIN Folio ON Cal_Act.id_folio = Folio.id_folio
      WHERE Folio.id_alumno = ? AND Actividad.id_grupo = ?
      ORDER BY Actividad.nombre
    ''', [idAlumno, idGrupo]);
  }

  @override
  Widget build(BuildContext context) {
    if (idAlumno <= 0 ||
        nombre.isEmpty ||
        apellido.isEmpty ||
        idGrupo.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: const Color(0xFF7F1E57), // Color guindo
        ),
        body: const Center(
          child: Text(
            'Todos los campos deben estar llenos y ser válidos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$nombre $apellido'),
        backgroundColor: const Color(0xFF924e7d), // Update primary color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actividades:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7F1E57)),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _getActividadesConCalificacion(),
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
                          'No hay actividades registradas para este alumno.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 16, color: Color(0xFF7F1E57)),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        itemCount: actividades.length,
                        itemBuilder: (context, index) {
                          final actividad = actividades[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text(
                                actividad['nombre'],
                                style:
                                    const TextStyle(color: Color(0xFF7F1E57)),
                              ),
                              trailing: Text(
                                'Calificación: ${actividad['calif']} / ${actividad['ponderacion']}',
                                style:
                                    const TextStyle(color: Color(0xFF7F1E57)),
                              ),
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
