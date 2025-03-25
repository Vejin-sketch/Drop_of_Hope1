import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _usernameKey = 'username';
  static const _emailKey = 'email';
  static const _isLoggedInKey = 'isLoggedIn';

  // 🔹 Save user session data (username and email)
  static Future<void> saveUserData(String username, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_usernameKey, username),
      prefs.setString(_emailKey, email),
      prefs.setBool(_isLoggedInKey, true),
    ]);
    print('User data saved: $username, $email');
    print('isLoggedIn set to true');
  }

  // 🔹 Get the logged-in user's username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // 🔹 Get the logged-in user's email
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // 🔹 Check if the user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    print('isLoggedIn retrieved: $isLoggedIn'); // Debugging
    return isLoggedIn;
  }

  // 🔹 Clear user session data (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_usernameKey),
      prefs.remove(_emailKey),
      prefs.setBool(_isLoggedInKey, false),
    ]);
    print('Session cleared');
  }
}