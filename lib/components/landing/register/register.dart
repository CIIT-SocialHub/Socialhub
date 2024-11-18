import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  late String _username;
  late String _email;
  late String _password;
  String? _errorMessage;

  Future<void> _register() async {
    // Validate email domain
    if (!_email.endsWith('@ciit.edu.ph')) {
      setState(() {
        _errorMessage = 'Please use a CIIT email (@ciit.edu.ph).';
      });
      return;
    }

    try {
      final conn = await MySqlConnection.connect(ConnectionSettings(
        host: '10.0.2.2',
        port: 3306,
        db: 'socialhub',
        user: 'flutter',
        password: 'flutter',
      ));

      final hashedPassword = sha256.convert(utf8.encode(_password)).toString();

      final result = await conn.query(
        'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
        [_username, _email, hashedPassword],
      );

      if (result.insertId != null) {
        Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
        });
      }

      await conn.close();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to the database.';
      });
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              onChanged: (value) => _username = value,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              onChanged: (value) => _email = value,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              onChanged: (value) => _password = value,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  const Color(0xFF00364D),
                ),
                foregroundColor: MaterialStateProperty.all<Color>(
                  Colors.white,
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              onPressed: _register,
              child: const Text('Register'),
            ),
            const SizedBox(height: 20),
            const Text('Already have an account? Login here.'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
