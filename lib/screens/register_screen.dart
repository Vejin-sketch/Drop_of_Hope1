import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropofhope/services/api_service.dart';
import 'package:dropofhope/screens/home_screen.dart';
import 'package:dropofhope/services/session_manager.dart';
import 'package:dropofhope/services/location_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _register() async {
    print('Register method called');
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final capitalizedFullName = _nameController.text
            .trim()
            .split(' ')
            .map((word) =>
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
            .join(' ');

        final response = await ApiService.register(
          capitalizedFullName,
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() => _isLoading = false);

        if (!mounted) return;

        if (response.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'])),
          );
        } else {
          final prefs = await SharedPreferences.getInstance();
          await SessionManager.saveUserData(
            capitalizedFullName,
            _emailController.text.trim(),
          );
          await SessionManager.saveUserId(response['user']['id']);

          final position = await LocationService.getUserLocation();

          if (position == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Please Enable Location Services and grant permission.")),
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
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.red,
      ),
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
                    height: 100, // Increased height to ensure it reaches the bottom
                    color: const Color(0xFF960000).withOpacity(0.3),
                  ),
                ),
                // Second wave layer (medium)
                ClipPath(
                  clipper: BottomWaveClipper(offset: 10),
                  child: Container(
                    height: 200,
                    color: const Color(0xFF960000).withOpacity(0.6),
                  ),
                ),
                // Third wave layer (darkest)
                ClipPath(
                  clipper: BottomWaveClipper(offset: 20),
                  child: Container(
                    height: 200,
                    color: const Color(0xFF960000),
                  ),
                ),
              ],
            ),
          ),
          // Wrap only the form content in SafeArea, not the wave
          SafeArea(
            bottom: false, // Allow the wave to extend to the bottom edge
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        if (value.trim().length > 50) {
                          return 'Name cannot exceed 50 characters';
                        }
                        if (RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Name cannot contain numbers';
                        }
                        if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
                          return 'Name cannot contain special characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Password must contain at least one uppercase letter';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Password must contain at least one number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 300), // Increased space to avoid overlap with wave
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
    // Draw the wave starting from the top, extending lower to reach the bottom
    path.quadraticBezierTo(
        size.width / 4, 40 + offset, size.width / 2, 20 + offset);
    path.quadraticBezierTo(
        size.width * 3 / 4,0 + offset, size.width, 20 + offset);
    // Connect to the bottom-right and bottom-left to close the path
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}