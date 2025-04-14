import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();
  late final String _baseUrl;

  ApiService() {
    // Use 127.0.0.1 when running on web, otherwise use 10.0.2.2 (for Android emulator)
    final host = kIsWeb ? '127.0.0.1' : '10.0.2.2';
    _baseUrl = 'http://$host:8000/api';
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
        return json.decode(decodedBody);
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
}
