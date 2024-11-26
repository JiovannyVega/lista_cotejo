import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_user_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/students_screen.dart'; // Importar la nueva pantalla de alumnos

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databasePath = join(await getDatabasesPath(), 'lista_cotejo.db');
  // await deleteDatabase(databasePath); // Eliminar la base de datos existente

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

      // Insertar 5 materias con validación
      await insertMateria(db, 'Matemáticas');
      await insertMateria(db, 'Física');
      await insertMateria(db, 'Quimica');
      await insertMateria(db, 'Biología');
      await insertMateria(db, 'Historia');

      // Insertar un usuario con validación
      final idMaestro = await db.insert(
        'Maestro',
        {
          'nombre': 'Erick',
          'apellido': 'Gamez',
          'carrera': 'ISC',
        },
      );

      await insertUsuario(
        db,
        {
          'username': 'Jiovanny',
          'password': 'Hola',
          'id_maestro': idMaestro,
        },
      );

      // Insertar 10 alumnos con validación
      await insertAlumno(db, {
        'nombre': 'Juan',
        'apellido': 'Pérez',
        'carrera': 'ISC',
        'año_ingreso': '2020-01-01'
      });
      await insertAlumno(db, {
        'nombre': 'María',
        'apellido': 'Gómez',
        'carrera': 'ISC',
        'año_ingreso': '2020-01-01'
      });
      await insertAlumno(db, {
        'nombre': 'Carlos',
        'apellido': 'López',
        'carrera': 'ISC',
        'año_ingreso': '2020-01-01'
      });
      await insertAlumno(db, {
        'nombre': 'Ana',
        'apellido': 'Martínez',
        'carrera': 'ISC',
        'año_ingreso': '2020-01-01'
      });
      await insertAlumno(db, {
        'nombre': 'Luis',
        'apellido': 'Hernández',
        'carrera': 'ISC',
        'año_ingreso': '2020-01-01'
      });
      await insertAlumno(db, {
        'nombre': 'Laura',
        'apellido': 'Díaz',
        'carrera': 'ISC',
        'año_ingreso': '2020-01-01'
      });
      await insertAlumno(db, {
        'nombre': 'José',
        'apellido': 'Ramírez',
        'carrera': 'ISC',
        'año_ingreso': '2020-01-01'
      });
      await insertAlumno(db, {
        'nombre': 'Marta',
        'apellido': 'Sánchez',
        'carrera': 'ISC',
        'año_ingreso': '2020-01-01'
      });
      await insertAlumno(db, {
        'nombre': 'Pedro',
        'apellido': 'Torres',
        'carrera': 'ISC',
        'año_ingreso': '2020-01-01'
      });
      await insertAlumno(db, {
        'nombre': 'Sofía',
        'apellido': 'Flores',
        'carrera': 'ISC',
        'año_ingreso': '2020-01-01'
      });
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
  for (var table in tables) {
    print(table['name']);
  }
}

Future<void> printTableContent(
    Future<Database> database, String tableName) async {
  final db = await database;
  final List<Map<String, dynamic>> rows = await db.query(tableName);
  print('Contenido de la tabla $tableName:');
  for (var row in rows) {
    print(row);
  }
}

Future<void> insertMateria(Database db, String nombre) async {
  if (nombre.isEmpty) {
    throw Exception('El nombre de la materia no puede estar vacío');
  }
  await db.insert('Materia', {'nombre': nombre});
}

Future<void> insertAlumno(Database db, Map<String, dynamic> alumno) async {
  if (alumno['nombre'].isEmpty ||
      alumno['apellido'].isEmpty ||
      alumno['carrera'].isEmpty ||
      alumno['año_ingreso'].isEmpty) {
    throw Exception('Todos los campos del alumno deben estar llenos');
  }
  await db.insert('Alumno', alumno);
}

Future<void> insertUsuario(Database db, Map<String, dynamic> usuario) async {
  if (usuario['username'].isEmpty ||
      usuario['password'].isEmpty ||
      usuario['id_maestro'] == null) {
    throw Exception('Todos los campos del usuario deben estar llenos');
  }
  await db.insert('Usuario', usuario);
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
        '/settings': (context) => SettingsScreen(
              database: database,
              username:
                  '', // Proveer un valor por defecto o ajustar según sea necesario
            ),
        '/students': (context) =>
            StudentsScreen(database: database), // Nueva ruta
      },
    );
  }
}
