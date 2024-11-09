import 'package:flutter/material.dart';
import 'package:socialhub/components/home/home.dart';
import 'package:socialhub/components/login/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social HUB',
      initialRoute: '/', // Start at the login page
      routes: {
        '/': (context) => const Login(), // Define the login page route
        '/home': (context) => const HomePage(), // Define the '/home' route
      },
      // Optionally, you can set onGenerateRoute if you want more control over route generation
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 8), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      });
    });
  }

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
            // You can add a loading indicator for a better user experience
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
