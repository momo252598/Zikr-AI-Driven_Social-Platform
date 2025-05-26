import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import './api_service.dart';

class AdminService {
  final ApiService _apiService = ApiService();
  late final String _baseUrl;

  AdminService() {
    // Set base URL based on platform
    final host = kIsWeb ? '127.0.0.1' : '192.168.1.9';
    _baseUrl = 'http://$host:8000';
  }

  // Get all pending sheikh verifications
  Future<List<dynamic>> getPendingSheikhVerifications() async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/accounts/admin/sheikh-verifications/'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        print(
            'Failed to fetch pending sheikh verifications: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }

      return json.decode(response.body);
    } catch (e) {
      print('Error fetching pending sheikh verifications: $e');
      return [];
    }
  }

  // Approve a sheikh verification
  Future<bool> approveSheikhVerification(int verificationId,
      {String? notes}) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/api/accounts/admin/sheikh-verifications/$verificationId/approve/'),
        headers: headers,
        body: notes != null ? json.encode({'notes': notes}) : json.encode({}),
      );

      if (response.statusCode != 200) {
        print('Failed to approve sheikh verification: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }

      return true;
    } catch (e) {
      print('Error approving sheikh verification: $e');
      return false;
    }
  }

  // Reject a sheikh verification
  Future<bool> rejectSheikhVerification(int verificationId,
      {required String notes}) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/api/accounts/admin/sheikh-verifications/$verificationId/reject/'),
        headers: headers,
        body: json.encode({'notes': notes}),
      );

      if (response.statusCode != 200) {
        print('Failed to reject sheikh verification: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }

      return true;
    } catch (e) {
      print('Error rejecting sheikh verification: $e');
      return false;
    }
  }
}
