import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class AddUserScreen extends StatefulWidget {
  final Future<Database> database;

  const AddUserScreen({super.key, required this.database});

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _carreraController = TextEditingController();
  String _errorMessage = '';

  Future<void> _addUser() async {
    final username = _usernameController.text;
    final password = _passwordController.text;
    final repeatPassword = _repeatPasswordController.text;
    final nombre = _nombreController.text;
    final apellido = _apellidoController.text;
    final carrera = _carreraController.text;

    if (username.isEmpty ||
        password.isEmpty ||
        repeatPassword.isEmpty ||
        nombre.isEmpty ||
        apellido.isEmpty ||
        carrera.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, complete todos los campos';
      });
      return;
    }

    if (password != repeatPassword) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden';
      });
      return;
    }

    final db = await widget.database;

    // Insertar en la tabla Maestro
    final idMaestro = await db.insert(
      'Maestro',
      {
        'nombre': nombre,
        'apellido': apellido,
        'carrera': carrera,
      },
    );

    // Insertar en la tabla Usuario
    await db.insert(
      'Usuario',
      {
        'username': username,
        'password': password,
        'id_maestro': idMaestro,
      },
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _repeatPasswordController,
              decoration: const InputDecoration(labelText: 'Repetir Password'),
              obscureText: true,
            ),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _apellidoController,
              decoration: const InputDecoration(labelText: 'Apellido'),
            ),
            TextField(
              controller: _carreraController,
              decoration: const InputDecoration(labelText: 'Carrera'),
            ),
            ElevatedButton(
              onPressed: _addUser,
              child: const Text('Agregar Usuario'),
            ),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
