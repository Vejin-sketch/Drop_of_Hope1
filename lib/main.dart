import 'package:flutter/material.dart';
import 'package:dropofhope/screens/splash_screen.dart'; // Import SplashScreen
import 'package:dropofhope/services/session_manager.dart'; // Import SessionManager

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  final isLoggedIn = await SessionManager.isLoggedIn(); // Check login state using SessionManager
  print('User is logged in: $isLoggedIn'); // Debugging
  runApp(DropOfHopeApp(isLoggedIn: isLoggedIn)); // Pass login state to DropOfHopeApp
}

class DropOfHopeApp extends StatelessWidget {
  final bool isLoggedIn;

  const DropOfHopeApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drop of Hope',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: SplashScreen(isLoggedIn: isLoggedIn), // Pass login state to SplashScreen
    );
  }
}