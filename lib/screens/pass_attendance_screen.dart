import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class PassAttendanceScreen extends StatefulWidget {
  final String clave;
  final DateTime date;

  const PassAttendanceScreen(
      {super.key, required this.clave, required this.date});

  @override
  _PassAttendanceScreenState createState() => _PassAttendanceScreenState();
}

class _PassAttendanceScreenState extends State<PassAttendanceScreen> {
  Map<int, bool> _asistencia = {};
  Map<int, bool> _participacion = {};
  Map<int, bool> _conducta = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await openDatabase('lista_cotejo.db');
    final alumnos = await _getAlumnos();
    for (var alumno in alumnos) {
      final idAlumno = alumno['id_alumno'];
      final idFolio = alumno['id_folio'];

      final asistencia = await db.query(
        'Asistencia',
        where: 'id_folio = ? AND fecha = ?',
        whereArgs: [idFolio, widget.date.toIso8601String()],
      );
      final participacion = await db.query(
        'Participacion',
        where: 'id_folio = ? AND fecha = ?',
        whereArgs: [idFolio, widget.date.toIso8601String()],
      );
      final conducta = await db.query(
        'Conducta',
        where: 'id_folio = ? AND fecha = ?',
        whereArgs: [idFolio, widget.date.toIso8601String()],
      );

      setState(() {
        _asistencia[idAlumno] =
            asistencia.isNotEmpty ? asistencia.first['asistencia'] == 1 : false;
        _participacion[idAlumno] = participacion.isNotEmpty
            ? participacion.first['participacion'] == 1
            : false;
        _conducta[idAlumno] =
            conducta.isNotEmpty ? conducta.first['conducta'] == 1 : false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getAlumnos() async {
    final db = await openDatabase('lista_cotejo.db');
    return await db.rawQuery('''
      SELECT Alumno.id_alumno, Alumno.nombre, Alumno.apellido, Folio.id_folio
      FROM Folio
      JOIN Alumno ON Folio.id_alumno = Alumno.id_alumno
      WHERE Folio.id_grupo = ?
      ORDER BY Alumno.nombre, Alumno.apellido
    ''', [widget.clave]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasar Asistencia'),
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
            return ListView.builder(
              itemCount: alumnos.length,
              itemBuilder: (context, index) {
                final alumno = alumnos[index];
                final idAlumno = alumno['id_alumno'];
                _asistencia[idAlumno] = _asistencia[idAlumno] ?? false;
                _participacion[idAlumno] = _participacion[idAlumno] ?? false;
                _conducta[idAlumno] = _conducta[idAlumno] ?? false;
                return Column(
                  children: [
                    ListTile(
                      title: Text('${alumno['nombre']} ${alumno['apellido']}'),
                    ),
                    SwitchListTile(
                      title: const Text('Asistencia'),
                      value: _asistencia[idAlumno]!,
                      onChanged: (value) {
                        setState(() {
                          _asistencia[idAlumno] = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Participación'),
                      value: _participacion[idAlumno]!,
                      onChanged: (value) {
                        setState(() {
                          _participacion[idAlumno] = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Conducta'),
                      value: _conducta[idAlumno]!,
                      onChanged: (value) {
                        setState(() {
                          _conducta[idAlumno] = value;
                        });
                      },
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_validateInputs()) {
            final db = await openDatabase('lista_cotejo.db');
            for (var alumno in await _getAlumnos()) {
              final idAlumno = alumno['id_alumno'];
              final idFolio = alumno['id_folio'];
              await db.insert(
                'Asistencia',
                {
                  'asistencia': _asistencia[idAlumno]! ? 1 : 0,
                  'fecha': DateTime.now().toIso8601String(),
                  'id_folio': idFolio,
                },
              );
              await db.insert(
                'Participacion',
                {
                  'participacion': _participacion[idAlumno]! ? 1 : 0,
                  'fecha': DateTime.now().toIso8601String(),
                  'id_folio': idFolio,
                },
              );
              await db.insert(
                'Conducta',
                {
                  'conducta': _conducta[idAlumno]! ? 1 : 0,
                  'fecha': DateTime.now().toIso8601String(),
                  'id_folio': idFolio,
                },
              );
            }
            Navigator.of(context).pop();
          } else {
            _showValidationError();
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  bool _validateInputs() {
    for (var key in _asistencia.keys) {
      if (_asistencia[key] == null ||
          _participacion[key] == null ||
          _conducta[key] == null) {
        return false;
      }
    }
    return true;
  }

  void _showValidationError() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error de validación'),
          content: const Text(
              'Por favor, asegúrese de llenar todos los campos correctamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
