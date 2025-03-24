import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart'; // We'll create this next

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final String _baseUrl;

  AuthService() {
    // Use 127.0.0.1 when running on web, otherwise use 10.0.2.2 (for Android emulator)
    final host = kIsWeb ? '127.0.0.1' : '10.0.2.2';
    _baseUrl = 'http://$host:8000/accounts';
  }

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Token storage keys
  static const String ACCESS_TOKEN_KEY = 'access_token';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';
  static const String USER_DATA_KEY = 'user_data';
  static const String USER_ID_KEY = 'user_id';
  static const String USERNAME_KEY = 'username';

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
  // Future<String?> getAccessToken() async {
  //   return await _storage.read(key: ACCESS_TOKEN_KEY);
  // }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: REFRESH_TOKEN_KEY);
  }

  // Clear all stored data (for logout)
  Future<Map<String, dynamic>> logout() async {
    try {
      // Get both tokens
      final refreshToken = await getRefreshToken();
      final accessToken = await getAccessToken();

      if (refreshToken != null && accessToken != null) {
        // Call the backend logout endpoint with Authorization header
        final response = await http.post(
          Uri.parse('$_baseUrl/logout/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $accessToken', // Add authorization header
          },
          body: jsonEncode(<String, String>{
            'refresh': refreshToken,
          }),
        );

        // Regardless of the response, clear the local storage
        await _storage.delete(key: ACCESS_TOKEN_KEY);
        await _storage.delete(key: REFRESH_TOKEN_KEY);
        await _storage.delete(key: USER_DATA_KEY);
        _currentUser = null;

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Successfully logged out',
          };
        } else {
          final Map<String, dynamic> responseData = json.decode(response.body);
          return {
            'success': false,
            'message': responseData['error'] ?? 'Failed to logout from server',
          };
        }
      } else {
        // No tokens found, just clear the local storage
        await _storage.delete(key: ACCESS_TOKEN_KEY);
        await _storage.delete(key: REFRESH_TOKEN_KEY);
        await _storage.delete(key: USER_DATA_KEY);
        _currentUser = null;

        return {
          'success': true,
          'message': 'Logged out locally',
        };
      }
    } catch (e) {
      // If there's an error, still clear the local storage
      await _storage.delete(key: ACCESS_TOKEN_KEY);
      await _storage.delete(key: REFRESH_TOKEN_KEY);
      await _storage.delete(key: USER_DATA_KEY);
      _currentUser = null;

      return {
        'success': false,
        'message': 'Error during logout: ${e.toString()}',
      };
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await getAccessToken() != null;
  }

  // Login with email or username
  Future<Map<String, dynamic>> login(
      String emailOrUsername, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email':
              emailOrUsername, // This field name is actually for either email or username
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
                gender: userData['gender'] ?? '');

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

  // Get current user ID
  Future<int?> getCurrentUserId() async {
    final userIdStr = await _storage.read(key: USER_ID_KEY);
    return userIdStr != null ? int.parse(userIdStr) : null;
  }

  // Get current username
  Future<String?> getCurrentUsername() async {
    return await _storage.read(key: USERNAME_KEY);
  }

  // Get access token (refreshes if needed)
  Future<String> getAccessToken() async {
    String? accessToken = await _storage.read(key: ACCESS_TOKEN_KEY);

    // Check if token exists and is valid
    if (accessToken == null) {
      // Try to refresh
      final refreshed = await refreshToken();
      if (!refreshed) {
        throw Exception('No authentication token available');
      }
      accessToken = await _storage.read(key: ACCESS_TOKEN_KEY);
    }

    return accessToken!;
  }

  // Save user info after login
  Future<void> saveUserInfo(Map<String, dynamic> userData, String accessToken,
      String refreshToken) async {
    await _storage.write(key: ACCESS_TOKEN_KEY, value: accessToken);
    await _storage.write(key: REFRESH_TOKEN_KEY, value: refreshToken);
    await _storage.write(key: USER_ID_KEY, value: userData['id'].toString());
    await _storage.write(key: USERNAME_KEY, value: userData['username']);
  }

  // Get Firebase authentication token from Django backend
  Future<String?> getFirebaseToken() async {
    try {
      // Make sure we have a valid access token
      final accessToken = await getAccessToken();

      // Use the chat API base URL instead of accounts
      final host = kIsWeb ? '127.0.0.1' : '10.0.2.2';
      final chatApiUrl = 'http://$host:8000/api/chat';

      // Call Django endpoint to get a Firebase custom token
      final response = await http.get(
        Uri.parse('$chatApiUrl/firebase-token/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['firebase_token'];
      } else {
        print('Failed to get Firebase token: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting Firebase token: $e');
      return null;
    }
  }
}
