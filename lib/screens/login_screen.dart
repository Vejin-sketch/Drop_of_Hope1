import 'package:flutter/material.dart';
import 'package:dropofhope/screens/register_screen.dart';
import 'package:dropofhope/screens/home_screen.dart';
import 'package:dropofhope/services/api_service.dart';
import 'package:dropofhope/services/session_manager.dart';
import 'package:dropofhope/services/location_service.dart';

void main() {
  runApp(MaterialApp(
    home: LoginScreen(),
  ));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await ApiService.login(
          _emailController.text,
          _passwordController.text,
        );

        setState(() => _isLoading = false);

        if (!mounted) return;

        if (response.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'])),
          );
        } else {
          if (response['user'] != null && response['user']['id'] != null) {
            await SessionManager.saveUserData(
              response['user']['name'],
              _emailController.text,
            );
            await SessionManager.saveUserId(response['user']['id']);

            final position = await LocationService.getUserLocation();

            if (position == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Enable Location Services.")),
              );
              return;
            }

            await ApiService.saveUserLocation(
              response['user']['id'],
              position.latitude,
              position.longitude,
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid server response')),
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Layered waves at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                // First wave layer (lightest)
                ClipPath(
                  clipper: BottomWaveClipper(offset: 0),
                  child: Container(
                    height: 150,
                    color: const Color(0xFF960000).withOpacity(0.3),
                  ),
                ),
                // Second wave layer (medium)
                ClipPath(
                  clipper: BottomWaveClipper(offset: 10),
                  child: Container(
                    height: 150,
                    color: const Color(0xFF960000).withOpacity(0.6),
                  ),
                ),
                // Third wave layer (darkest)
                ClipPath(
                  clipper: BottomWaveClipper(offset: 20),
                  child: Container(
                    height: 150,
                    color: const Color(0xFF960000),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'DropOfHope',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF960000),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Every Drop Counts',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 50),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter your email' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter your password' : null,
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Register",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 150), // Add space to avoid overlap with wave
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  final double offset;

  BottomWaveClipper({this.offset = 0});

  @override
  Path getClip(Size size) {
    Path path = Path();
    // Start at the top-left corner of the wave container
    path.moveTo(0, 0);
    // Draw the wave starting from the top
    path.quadraticBezierTo(
        size.width / 4, 40 + offset, size.width / 2, 20 + offset);
    path.quadraticBezierTo(
        size.width * 3 / 4, 0 + offset, size.width, 20 + offset);
    // Connect to the bottom-right and bottom-left to close the path
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}