import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late String _username;
  late String _password;
  String? _errorMessage;

  Future<void> _saveUserToPreferences(int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId); // Ensure userId is an integer
    await prefs.setString('username', username); // Save username
  }

  Future<void> _login() async {
    try {
      // Connect to the database
      final conn = await MySqlConnection.connect(ConnectionSettings(
        host: '10.0.2.2', // Android emulator, or use device IP
        port: 3306,
        db: 'socialhub',
        user: 'flutter',
        password: 'flutter',
      ));

      // Hash the entered password using SHA-256
      final hashedPassword = sha256.convert(utf8.encode(_password)).toString();

      // Prepare and execute the query
      final results = await conn.query(
        '''
        SELECT user_id, username, email, profile_pic, bio, created_at 
        FROM users 
        WHERE username = ? AND password = ?
        ''',
        [_username, hashedPassword],
      );

      if (results.isNotEmpty) {
        // Fetch user details
        final row = results.first;
        final userId = row['user_id'] as int;

        final username = row['username'] as String;

        // Save user details to SharedPreferences
        await _saveUserToPreferences(userId, username);

        // Navigate to the home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Handle login failure
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
      }

      // Close the connection
      await conn.close();
    } catch (e) {
      // Handle connection or query errors
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              onChanged: (value) => _username = value,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => _password = value,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  const Color(0xFF00364D),
                ),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              onPressed: _login,
              child: const Text('Login'),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/signup');
                },
                child: const Text(
                  'Don\'t have an account? Sign up here.',
                  style: TextStyle(color: Color(0xFF00364D)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
