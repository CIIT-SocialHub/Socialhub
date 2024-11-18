import 'package:flutter/material.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});

  @override
  State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 48,
                ),
                children: [
                  TextSpan(
                    text: 'Social',
                    style: TextStyle(
                      color: Color(0xFF4EC8F4),
                    ),
                  ),
                  TextSpan(
                    text: 'HUB',
                    style: TextStyle(
                      color: Color(0xFF00364D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  const Color(0xFF4EC8F4),
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
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  const Color(0xFF00364D),
                ),
                foregroundColor: WidgetStateProperty.all<Color>(
                  Colors.white,
                ),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/signup');
              },
              child: const Text('Signup'),
            ),
          ],
        ),
      ),
    );
  }
}
