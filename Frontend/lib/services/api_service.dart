import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';
import '../models/user.dart';

class ApiService {
  final AuthService _authService = AuthService();
  late final String _baseUrl;

  // Flag to prevent recursive retry loops
  bool _isRefreshing = false;

  // Maximum number of retries for a request
  static const int _maxRetries = 1;

  ApiService() {
    // Use 127.0.0.1 when running on web, otherwise use 192.168.1.9 (for Android emulator)
    final host = kIsWeb ? '127.0.0.1' : '192.168.1.9';
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

  // Helper method to handle unauthorized responses
  Future<bool> _handleUnauthorized() async {
    if (_isRefreshing) return false;

    try {
      _isRefreshing = true;
      final refreshed = await _authService.refreshToken();
      _isRefreshing = false;
      return refreshed;
    } catch (e) {
      _isRefreshing = false;
      return false;
    }
  }

  // Helper method for making authenticated GET requests with proper encoding and retry logic
  Future<dynamic> get(String endpoint, {int retryCount = 0}) async {
    try {
      // Get headers with fresh token
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      );

      // Use utf8.decode to properly handle Arabic characters
      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final parsed = json.decode(decodedBody);
        return _ensureCorrectTypes(parsed); // Convert string IDs to integers
      } else if (response.statusCode == 401 && retryCount < _maxRetries) {
        // Handle Unauthorized - token may be expired
        print(
            'Unauthorized response for GET $endpoint. Attempting token refresh...');
        final refreshed = await _handleUnauthorized();

        if (refreshed) {
          // Retry with new token
          print('Token refreshed. Retrying GET request for $endpoint');
          return await get(endpoint, retryCount: retryCount + 1);
        } else {
          throw Exception('Authentication failed. Please log in again.');
        }
      } else {
        throw Exception(
            'Failed to load data: ${response.statusCode} - $decodedBody');
      }
    } catch (e) {
      throw Exception('Error in GET request: $e');
    }
  }

  // Helper method for making authenticated POST requests with proper encoding and retry logic
  Future<dynamic> post(String endpoint, Map<String, dynamic> data,
      {int retryCount = 0}) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      // Use utf8.decode to properly handle Arabic characters
      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(decodedBody);
      } else if (response.statusCode == 401 && retryCount < _maxRetries) {
        // Handle Unauthorized - token may be expired
        print(
            'Unauthorized response for POST $endpoint. Attempting token refresh...');
        final refreshed = await _handleUnauthorized();

        if (refreshed) {
          // Retry with new token
          print('Token refreshed. Retrying POST request for $endpoint');
          return await post(endpoint, data, retryCount: retryCount + 1);
        } else {
          throw Exception('Authentication failed. Please log in again.');
        }
      } else {
        throw Exception(
            'Failed to post data: ${response.statusCode} - $decodedBody');
      }
    } catch (e) {
      throw Exception('Error in POST request: $e');
    }
  }

  // Helper method for making authenticated PUT requests with proper encoding and retry logic
  Future<dynamic> put(String endpoint, Map<String, dynamic> data,
      {int retryCount = 0}) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      // Use utf8.decode to properly handle Arabic characters
      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(decodedBody);
      } else if (response.statusCode == 401 && retryCount < _maxRetries) {
        // Handle Unauthorized - token may be expired
        print(
            'Unauthorized response for PUT $endpoint. Attempting token refresh...');
        final refreshed = await _handleUnauthorized();

        if (refreshed) {
          // Retry with new token
          print('Token refreshed. Retrying PUT request for $endpoint');
          return await put(endpoint, data, retryCount: retryCount + 1);
        } else {
          throw Exception('Authentication failed. Please log in again.');
        }
      } else {
        throw Exception(
            'Failed to update data: ${response.statusCode} - $decodedBody');
      }
    } catch (e) {
      throw Exception('Error in PUT request: $e');
    }
  }

  // Helper method for making authenticated DELETE requests with retry logic
  Future<dynamic> delete(String endpoint, {int retryCount = 0}) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          return json.decode(utf8.decode(response.bodyBytes));
        }
        return {'success': true};
      } else if (response.statusCode == 401 && retryCount < _maxRetries) {
        // Handle Unauthorized - token may be expired
        print(
            'Unauthorized response for DELETE $endpoint. Attempting token refresh...');
        final refreshed = await _handleUnauthorized();

        if (refreshed) {
          // Retry with new token
          print('Token refreshed. Retrying DELETE request for $endpoint');
          return await delete(endpoint, retryCount: retryCount + 1);
        } else {
          throw Exception('Authentication failed. Please log in again.');
        }
      } else {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error in DELETE request: $e');
    }
  }

  // Helper method for updating user profile with retry logic
  Future<dynamic> updateUserProfile(Map<String, dynamic> userData,
      {int retryCount = 0}) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/accounts/update-profile/'),
        headers: headers,
        body: json.encode(userData),
      );

      // Use utf8.decode to properly handle Arabic characters
      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final updatedUserData = json.decode(decodedBody);
        // Update stored user data
        await _authService.storeUserData(User.fromJson(updatedUserData));
        return updatedUserData;
      } else if (response.statusCode == 401 && retryCount < _maxRetries) {
        // Handle Unauthorized - token may be expired
        print(
            'Unauthorized response for update profile. Attempting token refresh...');
        final refreshed = await _handleUnauthorized();

        if (refreshed) {
          // Retry with new token
          print('Token refreshed. Retrying update profile request');
          return await updateUserProfile(userData, retryCount: retryCount + 1);
        } else {
          throw Exception('Authentication failed. Please log in again.');
        }
      } else {
        throw Exception(
            'Failed to update profile: ${response.statusCode} - $decodedBody');
      }
    } catch (e) {
      throw Exception('Error in update profile request: $e');
    }
  }

  // Method to change user password with retry logic
  Future<dynamic> changePassword(
      String oldPassword, String newPassword, String confirmPassword,
      {int retryCount = 0}) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/accounts/change-password/'),
        headers: headers,
        body: json.encode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(decodedBody);
      } else if (response.statusCode == 401 && retryCount < _maxRetries) {
        // Handle Unauthorized - token may be expired
        print(
            'Unauthorized response for change password. Attempting token refresh...');
        final refreshed = await _handleUnauthorized();

        if (refreshed) {
          // Retry with new token
          print('Token refreshed. Retrying change password request');
          return await changePassword(oldPassword, newPassword, confirmPassword,
              retryCount: retryCount + 1);
        } else {
          throw Exception('Authentication failed. Please log in again.');
        }
      } else {
        throw Exception(
            'Failed to change password: ${response.statusCode} - $decodedBody');
      }
    } catch (e) {
      throw Exception('Error in change password request: $e');
    }
  }

  // Method to validate token and ensure it's working properly
  Future<bool> validateAuthentication() async {
    try {
      // Try to access a simple endpoint that requires authentication
      await get('/accounts/check-auth/');
      return true;
    } catch (e) {
      print('Authentication validation failed: $e');
      // If we can't access the endpoint, there might be an issue with the token
      return false;
    }
  }
}
