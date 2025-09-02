import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      return 'http://192.168.124.154:3000'; // Replace this if needed
    }
  }

  // 🔹 LOGIN USER
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        return {
          'error': data['message'] ?? 'Invalid response from server'
        };
      }
    } catch (e) {
      return {'error': 'Connection failed'};
      }
  }

  // 🔹 REGISTER USER
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'error': 'Connection failed'};
    }
  }

  static Future<void> saveUserLocation(int userId, double lat, double lng) async {
    final response = await http.put(
      Uri.parse('${baseUrl}/profile'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'latitude': lat,
        'longitude': lng,
      }),
    );

    final data = json.decode(response.body);
    if (data['success'] != true) {
      throw Exception("Failed to update location");
    }
  }

  // 🔹 FETCH RECENT REQUESTS
  static Future<List<dynamic>> fetchRecentRequests() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/requests'),
      );

      final data = json.decode(response.body);
      if (data['requests'] != null) {
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
    // ❗ Note: This route does not exist in your current backend
    throw UnimplementedError("This route is not yet implemented on the backend.");
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
      final updatedProfileData = {
        'userId': profileData['userId'],
        'lastDonationDate': profileData['lastDonationDate'],
        'bloodGroup': profileData['bloodGroup'],
        'gender': profileData['gender'],
        'age': profileData['age'],
        'weight': profileData['weight'],
        'location': profileData['location'],
        'hasTattoo': profileData['hasTattoo'],
        'isHivPositive': profileData['isHivPositive'],
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

  static Future<List<dynamic>> getMatchesForDonor(int donorId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/matches/requests?donorId=$donorId'),
      );

      final data = json.decode(response.body);

      if (data['matches'] != null) {
        return data['matches'];
      } else {
        throw Exception('No matches found');
      }
    } catch (e) {
      throw Exception('Connection failed: \$e');
    }
  }

  //Responses
  static Future<int> logHelpResponse(int donorId, int requestId, Map<String, dynamic> request) async {
    final response = await http.post(
      Uri.parse('${baseUrl}/responses'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'donor_id': donorId,
        'request_id': requestId,
      }),
    );

    final data = json.decode(response.body);
    final prefs = await SharedPreferences.getInstance();

    if (response.statusCode == 201 && data['response_id'] != null) {
      await prefs.setInt('activeResponseId', data['response_id']);
      await prefs.setString('activeRequest', json.encode(request));
      return data['response_id'];
    } else if (response.statusCode == 409) {
      throw Exception('already responded');
    } else {
      throw Exception(data['message'] ?? 'Failed to respond');
    }
  }

  static Future<void> markResponseFulfilled(int responseId) async {
    final response = await http.put(
      Uri.parse('${baseUrl}/responses/$responseId/fulfill'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to mark as fulfilled');
    }
  }

  static Future<void> cancelResponse(int responseId, String reason) async {
    final response = await http.put(
      Uri.parse('${baseUrl}/responses/$responseId/cancel'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'cancel_reason': reason}),
    );

    final data = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to cancel response');
    }
  }

  // 🔹 Add this to ApiService class
  static Future<void> createBloodRequest(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${baseUrl}/requests'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    final resData = json.decode(response.body);
    if (response.statusCode != 201) {
      throw Exception(resData['message'] ?? 'Request failed');
    }
  }

}
