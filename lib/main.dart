import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:socialhub/components/home/home.dart';
import 'package:socialhub/components/landing/landing.dart';
import 'package:socialhub/components/landing/login/login.dart';
import 'package:socialhub/components/landing/register/register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    runApp(const MyApp());
    await Firebase.initializeApp();
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social HUB',
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const Landing(),
        '/login': (context) => const Login(),
        '/signup': (context) => const Register(),
        // Modify the /home route to pass arguments
        '/home': (context) => const HomePage(),
      },
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
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushReplacementNamed(context, '/');
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
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
