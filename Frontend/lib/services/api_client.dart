import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiClient {
  final String baseUrl;
  final AuthService _authService = AuthService();

  ApiClient({required this.baseUrl});

  Future<http.Response> get(String path) async {
    return _requestWithToken(
      () async => await http.get(
        Uri.parse('$baseUrl$path'),
        headers: await _getHeaders(),
      ),
    );
  }

  Future<http.Response> post(String path, dynamic data) async {
    return _requestWithToken(
      () async => await http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      ),
    );
  }

  Future<http.Response> put(String path, dynamic data) async {
    return _requestWithToken(
      () async => await http.put(
        Uri.parse('$baseUrl$path'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      ),
    );
  }

  Future<http.Response> delete(String path) async {
    return _requestWithToken(
      () async => await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: await _getHeaders(),
      ),
    );
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _requestWithToken(
      Future<http.Response> Function() request) async {
    http.Response response = await request();

    // If unauthorized - token might be expired
    if (response.statusCode == 401) {
      // Try to refresh token
      final isRefreshed = await _authService.refreshToken();

      if (isRefreshed) {
        // Retry the original request with new token
        response = await request();
      }
    }

    return response;
  }
}
