import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _userIdKey = 'userId';
  static const _usernameKey = 'username';
  static const _emailKey = 'email';
  static const _isLoggedInKey = 'isLoggedIn';

  // 🔹 Save user session data
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

  // 🔹 Save user ID
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    print('User ID saved: $userId');
  }

  // 🔹 Get stored user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // 🔹 Get stored username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // 🔹 Get stored email
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // 🔹 Check login status
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    print('isLoggedIn retrieved: $isLoggedIn');
    return isLoggedIn;
  }

  // 🔹 Clear user session data (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_userIdKey),
      prefs.remove(_usernameKey),
      prefs.remove(_emailKey),
      prefs.setBool(_isLoggedInKey, false),
    ]);
    print('Session cleared');
  }
}