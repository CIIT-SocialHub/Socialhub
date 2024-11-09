import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:socialhub/components/home/home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late String _username;
  late String _password;
  String? _errorMessage;

  Future<void> _login() async {
    try {
      // Connect to MySQL database
      final conn = await MySqlConnection.connect(ConnectionSettings(
        host: '10.0.2.2', // Use this for Android emulator
        port: 3306,
        db: 'socialhub',
        user: 'flutter',
        password: 'flutter',
      ));

      // Query to verify login credentials (no hashing for password)
      final results = await conn.query(
        'SELECT user_id, username, email, password, date_joined FROM users WHERE username = ? AND password = ?',
        [_username, _password], // Don't hash the password
      );

      if (results.isNotEmpty) {
        // Successful login
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Login failed
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
      }

      // Close the connection
      await conn.close();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to the database';
      });
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              onChanged: (value) => _username = value,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              onChanged: (value) => _password = value,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
