import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      return 'http://your-ip:3000'; // Replace with your server IP
    }
  }

  // 🔹 LOGIN USER
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      return data; // Return the response without saving data
    } catch (e) {
      return {'error': 'Connection failed'};
    }
  }

  // 🔹 REGISTER USER
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      return data; // Return the response without saving data
    } catch (e) {
      return {'error': 'Connection failed'};
    }
  }

  // 🔹 FETCH RECENT REQUESTS
  static Future<List<dynamic>> fetchRecentRequests() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/recent-requests'),
      );

      final data = json.decode(response.body);
      if (data['success']) {
        return data['requests'];
      } else {
        throw Exception('Failed to fetch recent requests');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  // 🔹 FETCH BLOOD STOCK LEVELS
  static Future<List<dynamic>> fetchBloodStock() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/blood-stock'),
      );

      final data = json.decode(response.body);
      if (data['success']) {
        return data['stock'];
      } else {
        throw Exception('Failed to fetch blood stock');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  // 🔹 FETCH PROFILE DETAILS
  static Future<Map<String, dynamic>> fetchProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/profile?userId=$userId'),
      );

      final data = json.decode(response.body);
      if (data['success']) {
        return data['profile'];
      } else {
        throw Exception('Failed to fetch profile details');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  // 🔹 UPDATE PROFILE DETAILS
  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    try {
      // Ensure optional fields are handled properly
      final updatedProfileData = {
        'userId': profileData['userId'], // Required field
        'lastDonationDate': profileData['lastDonationDate'], // Optional
        'bloodGroup': profileData['bloodGroup'], // Optional
        'gender': profileData['gender'], // Optional
        'age': profileData['age'], // Optional
        'weight': profileData['weight'], // Optional
        'location': profileData['location'], // Optional
        'hasTattoo': profileData['hasTattoo'], // Optional (default: false)
        'isHivPositive': profileData['isHivPositive'], // Optional (default: false)
      };

      final response = await http.put(
        Uri.parse('${baseUrl}/profile'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(updatedProfileData),
      );

      final data = json.decode(response.body);
      if (data['success']) {
        return data;
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }
}