import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';
import '../models/user.dart'; // We'll create this next

class ApiService {
  final AuthService _authService = AuthService();
  late final String _baseUrl;

  ApiService() {
    // Use 127.0.0.1 when running on web, otherwise use 192.168.1.7 (for Android emulator)
    final host = kIsWeb ? '127.0.0.1' : '192.168.1.7';
    _baseUrl = 'http://$host:8000/api';
  }

  // Add this getter to access the base URL
  String get baseUrl => _baseUrl;

  // Add this method to get headers for requests
  Future<Map<String, String>> getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
      'Accept-Charset': 'utf-8',
    };
  }

  // Add this helper method to your ApiService class
  dynamic _ensureCorrectTypes(dynamic data) {
    if (data is Map) {
      // Handle IDs and numeric values that might be strings
      return data.map((key, value) {
        // Try to convert string IDs to integers
        if (key == 'id' && value is String) {
          return MapEntry(key, int.tryParse(value) ?? value);
        } else if (value is Map) {
          return MapEntry(key, _ensureCorrectTypes(value));
        } else if (value is List) {
          return MapEntry(key, _ensureCorrectTypes(value));
        } else {
          return MapEntry(key, value);
        }
      });
    } else if (data is List) {
      return data.map((item) => _ensureCorrectTypes(item)).toList();
    }
    return data;
  }

  // Helper method for making authenticated GET requests with proper encoding
  Future<dynamic> get(String endpoint) async {
    try {
      final token = await _authService.getAccessToken();
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept-Charset': 'utf-8',
        },
      );

      // Use utf8.decode to properly handle Arabic characters
      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final parsed = json.decode(decodedBody);
        return _ensureCorrectTypes(parsed); // Convert string IDs to integers
      } else {
        throw Exception(
            'Failed to load data: ${response.statusCode} - $decodedBody');
      }
    } catch (e) {
      throw Exception('Error in GET request: $e');
    }
  }

  // Helper method for making authenticated POST requests with proper encoding
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getAccessToken();
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept-Charset': 'utf-8',
        },
        body: json.encode(data),
      );

      // Use utf8.decode to properly handle Arabic characters
      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(decodedBody);
      } else {
        throw Exception(
            'Failed to post data: ${response.statusCode} - $decodedBody');
      }
    } catch (e) {
      throw Exception('Error in POST request: $e');
    }
  }

  // Helper method for making authenticated PUT requests with proper encoding
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getAccessToken();
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept-Charset': 'utf-8',
        },
        body: json.encode(data),
      );

      // Use utf8.decode to properly handle Arabic characters
      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(decodedBody);
      } else {
        throw Exception(
            'Failed to update data: ${response.statusCode} - $decodedBody');
      }
    } catch (e) {
      throw Exception('Error in PUT request: $e');
    }
  }

  // Helper method for making authenticated DELETE requests
  Future<dynamic> delete(String endpoint) async {
    try {
      final token = await _authService.getAccessToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          return json.decode(utf8.decode(response.bodyBytes));
        }
        return {'success': true};
      } else {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error in DELETE request: $e');
    }
  }

  // Helper method for updating user profile
  Future<dynamic> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final token = await _authService.getAccessToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/accounts/update-profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept-Charset': 'utf-8',
        },
        body: json.encode(userData),
      );

      // Use utf8.decode to properly handle Arabic characters
      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final updatedUserData = json.decode(decodedBody);
        // Update stored user data
        await _authService.storeUserData(User.fromJson(updatedUserData));
        return updatedUserData;
      } else {
        throw Exception(
            'Failed to update profile: ${response.statusCode} - $decodedBody');
      }
    } catch (e) {
      throw Exception('Error in update profile request: $e');
    }
  }

  // Method to change user password
  Future<dynamic> changePassword(
      String oldPassword, String newPassword, String confirmPassword) async {
    try {
      final token = await _authService.getAccessToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/accounts/change-password/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(decodedBody);
      } else {
        throw Exception(
            'Failed to change password: ${response.statusCode} - $decodedBody');
      }
    } catch (e) {
      throw Exception('Error in change password request: $e');
    }
  }
}
