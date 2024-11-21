import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialhub/components/home/home.dart';
import 'package:socialhub/components/landing/landing.dart';
import 'package:socialhub/components/landing/login/login.dart';
import 'package:socialhub/components/landing/register/register.dart';
import 'package:socialhub/components/message/chats/chat.dart';
import 'package:socialhub/components/message/message.dart';
import 'package:socialhub/components/profile/editprofile.dart';
import 'package:socialhub/components/profile/profile.dart';

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

  Future<Map<String, dynamic>> getUserDetailsFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? -1;
    final username = prefs.getString('username') ?? '';
    return {'userId': userId, 'username': username};
  }

  MaterialPageRoute _buildFutureRoute({
    required Widget Function(Map<String, dynamic> userDetails) builder,
  }) {
    return MaterialPageRoute(
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: getUserDetailsFromPreferences(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError || !snapshot.hasData) {
            return const Scaffold(
              body: Center(child: Text('Error loading user details')),
            );
          }
          return builder(snapshot.data!);
        },
      ),
    );
  }

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
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/profile':
            return _buildFutureRoute(
              builder: (userDetails) => ProfilePage(
                userId: userDetails['userId'],
                username: userDetails['username'],
              ),
            );
          case '/messages':
            return _buildFutureRoute(
              builder: (userDetails) => MessagePage(
                currentUserId: userDetails['userId'],
              ),
            );
          case '/home':
            return _buildFutureRoute(
              builder: (userDetails) => HomePage(
                userId: userDetails['userId'],
                username: userDetails['username'],
              ),
            );
          case '/editprofile':
            if (settings.arguments is int) {
              final userId = settings.arguments as int;
              return MaterialPageRoute(
                builder: (context) => EditProfilePage(userId: userId),
              );
            }
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Invalid arguments for /editprofile')),
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Route not found')),
              ),
            );
        }
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
