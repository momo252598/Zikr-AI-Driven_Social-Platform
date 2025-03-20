import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart'; // We'll create this next

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _baseUrl = 'http://10.0.2.2:8000/accounts';

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Token storage keys
  static const String ACCESS_TOKEN_KEY = 'access_token';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';
  static const String USER_DATA_KEY = 'user_data';

  // Store tokens securely
  Future<void> storeTokens(
      {required String accessToken, required String refreshToken}) async {
    await _storage.write(key: ACCESS_TOKEN_KEY, value: accessToken);
    await _storage.write(key: REFRESH_TOKEN_KEY, value: refreshToken);
  }

  // Store user data
  Future<void> storeUserData(User user) async {
    _currentUser = user;
    await _storage.write(key: USER_DATA_KEY, value: jsonEncode(user.toJson()));
  }

  // Get user data
  Future<User?> getUserData() async {
    if (_currentUser != null) return _currentUser;

    final userData = await _storage.read(key: USER_DATA_KEY);
    if (userData != null) {
      _currentUser = User.fromJson(jsonDecode(userData));
      return _currentUser;
    }
    return null;
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: ACCESS_TOKEN_KEY);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: REFRESH_TOKEN_KEY);
  }

  // Clear all stored data (for logout)
  Future<void> logout() async {
    await _storage.delete(key: ACCESS_TOKEN_KEY);
    await _storage.delete(key: REFRESH_TOKEN_KEY);
    await _storage.delete(key: USER_DATA_KEY);
    _currentUser = null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await getAccessToken() != null;
  }

  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData.containsKey('access') &&
            responseData.containsKey('refresh')) {
          await storeTokens(
              accessToken: responseData['access'],
              refreshToken: responseData['refresh']);

          // Create a user object from the complete user data in the response
          if (responseData.containsKey('user')) {
            final userData = responseData['user'];
            final user = User(
                id: userData['id'],
                username: userData['username'],
                email: userData['email'],
                userType: userData['user_type'],
                name:
                    "${userData['first_name']} ${userData['last_name']}".trim(),
                phoneNumber: userData['phone_number'],
                birthDate: userData['birth_date'] != null
                    ? DateTime.parse(userData['birth_date'])
                    : null,
                profilePicture: userData['profile_picture'],
                bio: userData['bio'],
                isVerified: userData['is_verified'],
                createdAt: DateTime.parse(userData['created_at']),
                firstName: userData['first_name'],
                lastName: userData['last_name'],
                dateJoined: DateTime.parse(userData['date_joined']),
                lastLogin: userData['last_login'] != null
                    ? DateTime.parse(userData['last_login'])
                    : null,
                gender: userData['gender'] ?? ''); // Include gender field

            await storeUserData(user);
          }
        }
      }

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': responseData['detail'] ?? 'Unknown error',
        'data': responseData
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Connection error: ${e.toString()}',
        'data': null
      };
    }
  }

  // Replace the fetchUserProfile method with a simple getter
  Future<User?> getCurrentUser() async {
    return await getUserData();
  }

  // Refresh token when access token expires
  Future<bool> refreshToken() async {
    final refreshToken = await getRefreshToken();

    if (refreshToken == null) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: ACCESS_TOKEN_KEY, value: data['access']);
        return true;
      } else {
        // If refresh token is invalid, log the user out
        await logout();
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
