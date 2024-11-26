import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_user_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databasePath = join(await getDatabasesPath(), 'lista_cotejo.db');
  await deleteDatabase(databasePath); // Eliminar la base de datos existente

  final database = openDatabase(
    databasePath,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE Materia(
          id_materia INTEGER PRIMARY KEY,
          nombre TEXT
        );
      ''');
      await db.execute('''
        CREATE TABLE Grupo(
          id_grupo INTEGER PRIMARY KEY,
          clave TEXT,
          id_maestro INTEGER,
          id_materia INTEGER,
          FOREIGN KEY (id_materia) REFERENCES Materia(id_materia),
          FOREIGN KEY (id_maestro) REFERENCES Maestro(id_maestro)
        );
      ''');
      await db.execute('''
        CREATE TABLE Folio(
          id_folio INTEGER PRIMARY KEY,
          id_grupo INTEGER,
          id_alumno INTEGER,
          FOREIGN KEY (id_grupo) REFERENCES Grupo(id_grupo),
          FOREIGN KEY (id_alumno) REFERENCES Alumno(id_alumno)
        );
      ''');
      await db.execute('''
        CREATE TABLE Maestro(
          id_maestro INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT,
          apellido TEXT,
          carrera TEXT
        );
      ''');
      await db.execute('''
        CREATE TABLE Alumno(
          id_alumno INTEGER PRIMARY KEY,
          nombre TEXT,
          apellido TEXT,
          carrera TEXT,
          año_ingreso DATETIME
        );
      ''');
      await db.execute('''
        CREATE TABLE Asistencia(
          id_asistencia INTEGER PRIMARY KEY,
          asistencia BIT,
          fecha DATE,
          id_folio INTEGER,
          FOREIGN KEY (id_folio) REFERENCES Folio(id_folio)
        );
      ''');
      await db.execute('''
        CREATE TABLE Conducta(
          id_conducta INTEGER PRIMARY KEY,
          conducta BIT,
          fecha DATE,
          id_folio INTEGER,
          FOREIGN KEY (id_folio) REFERENCES Folio(id_folio)
        );
      ''');
      await db.execute('''
        CREATE TABLE Participacion(
          id_participacion INTEGER PRIMARY KEY,
          participacion BIT,
          fecha DATE,
          id_folio INTEGER,
          FOREIGN KEY (id_folio) REFERENCES Folio(id_folio)
        );
      ''');
      await db.execute('''
        CREATE TABLE Actividad(
          id_actividad INTEGER PRIMARY KEY,
          nombre TEXT,
          desc TEXT,
          fecha DATE,
          ponderacion BIT,
          id_grupo INTEGER,
          FOREIGN KEY (id_grupo) REFERENCES Grupo(id_grupo)
        );
      ''');
      await db.execute('''
        CREATE TABLE Cal_Act(
          id_cal INTEGER,
          calif TINYINT,
          id_actividad INTEGER,
          id_folio INTEGER,
          FOREIGN KEY (id_actividad) REFERENCES Actividad(id_actividad),
          FOREIGN KEY (id_folio) REFERENCES Folio(id_folio)
        );
      ''');
      await db.execute('''
        CREATE TABLE Usuario(
          id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT,
          password TEXT,
          id_maestro INTEGER,
          FOREIGN KEY (id_maestro) REFERENCES Maestro(id_maestro)
        );
      ''');

      // Insertar 5 materias
      await db.insert('Materia', {'nombre': 'Matemáticas'});
      await db.insert('Materia', {'nombre': 'Física'});
      await db.insert('Materia', {'nombre': 'Quimica'});
      await db.insert('Materia', {'nombre': 'Biología'});
      await db.insert('Materia', {'nombre': 'Historia'});

      // Insertar un usuario con los detalles proporcionados
      final idMaestro = await db.insert(
        'Maestro',
        {
          'nombre': 'Erick',
          'apellido': 'Gamez',
          'carrera': 'ISC',
        },
      );

      await db.insert(
        'Usuario',
        {
          'username': 'Jiovanny',
          'password': 'Hola',
          'id_maestro': idMaestro,
        },
      );
    },
    version: 1,
  );

  // Listar las tablas en la base de datos
  listTables(database);

  // Imprimir el contenido de la tabla Usuario
  printTableContent(database, 'Usuario');

  runApp(MainApp(database: database));
}

Future<void> listTables(Future<Database> database) async {
  final db = await database;
  final List<Map<String, dynamic>> tables =
      await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
  print('Tablas en la base de datos:');
  tables.forEach((table) {
    print(table['name']);
  });
}

Future<void> printTableContent(
    Future<Database> database, String tableName) async {
  final db = await database;
  final List<Map<String, dynamic>> rows = await db.query(tableName);
  print('Contenido de la tabla $tableName:');
  rows.forEach((row) {
    print(row);
  });
}

class MainApp extends StatelessWidget {
  final Future<Database> database;

  const MainApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(database: database),
        '/home': (context) => HomeScreen(
            database: database, username: ''), // Proveer un valor por defecto
        '/add_user': (context) => AddUserScreen(database: database),
      },
    );
  }
}
