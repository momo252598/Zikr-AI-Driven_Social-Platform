import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:software_graduation_project/services/api_service.dart';

class PasswordResetService {
  late final String _baseUrl;
  final ApiService _apiService = ApiService();

  PasswordResetService() {
    // Use 127.0.0.1 when running on web, otherwise use 192.168.1.6 (for Android emulator)
    final host = kIsWeb ? '127.0.0.1' : '192.168.1.6';
    _baseUrl = 'http://$host:8000/api';
  }

  /// Request a password reset token
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/accounts/request-password-reset/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
        }),
      );

      // Decode response with proper UTF-8 handling
      final responseBody = utf8.decode(response.bodyBytes);
      final data = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['success'],
        };
      } else {
        return {
          'success': false,
          'message':
              data['error'] ?? 'حدث خطأ أثناء طلب إعادة تعيين كلمة المرور.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ في الاتصال: $e',
      };
    }
  }

  /// Verify a password reset code
  Future<Map<String, dynamic>> verifyResetCode(
      String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/accounts/verify-reset-code/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'token': code,
        }),
      );

      // Decode response with proper UTF-8 handling
      final responseBody = utf8.decode(response.bodyBytes);
      final data = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['success'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'رمز التحقق غير صحيح.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ في الاتصال: $e',
      };
    }
  }

  /// Reset password with a verified code
  Future<Map<String, dynamic>> resetPassword(String email, String code,
      String newPassword, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/accounts/reset-password/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'token': code,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      // Decode response with proper UTF-8 handling
      final responseBody = utf8.decode(response.bodyBytes);
      final data = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['success'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'فشل في إعادة تعيين كلمة المرور.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ في الاتصال: $e',
      };
    }
  }
}
