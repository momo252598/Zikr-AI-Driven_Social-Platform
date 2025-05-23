import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'dart:async'; // Added for timers

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final String _baseUrl;

  // Added for token expiration tracking
  static const String TOKEN_EXPIRY_KEY = 'token_expiry_time';
  // Buffer time before token expiration to refresh (5 minutes)
  static const int TOKEN_REFRESH_BUFFER_MINUTES = 5;
  Timer? _tokenRefreshTimer;

  AuthService() {
    // Use 127.0.0.1 when running on web, otherwise use 192.168.1.9 (for Android emulator)
    final host = kIsWeb ? '127.0.0.1' : '192.168.1.9';
    _baseUrl = 'http://$host:8000/api/accounts';
  }

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Token storage keys
  static const String ACCESS_TOKEN_KEY = 'access_token';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';
  static const String USER_DATA_KEY = 'user_data';
  static const String USER_ID_KEY = 'user_id';
  static const String USERNAME_KEY = 'username';

  // Store tokens securely with expiration time
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    int accessTokenLifetimeMinutes = 24 * 60, // Default: 1 day in minutes
  }) async {
    await _storage.write(key: ACCESS_TOKEN_KEY, value: accessToken);
    await _storage.write(key: REFRESH_TOKEN_KEY, value: refreshToken);

    // Calculate and store expiration time
    final expiryTime =
        DateTime.now().add(Duration(minutes: accessTokenLifetimeMinutes));
    await _storage.write(
        key: TOKEN_EXPIRY_KEY, value: expiryTime.toIso8601String());
    print("Token will expire at: $expiryTime");

    // Set up auto-refresh timer
    _setupTokenRefreshTimer(expiryTime);
  }

  // Setup automatic token refresh before expiration
  void _setupTokenRefreshTimer(DateTime expiryTime) {
    // Cancel any existing timer
    _tokenRefreshTimer?.cancel();

    // Calculate when to refresh (5 minutes before expiry)
    final refreshTime = expiryTime
        .subtract(const Duration(minutes: TOKEN_REFRESH_BUFFER_MINUTES));
    final now = DateTime.now();

    if (refreshTime.isAfter(now)) {
      final timeUntilRefresh = refreshTime.difference(now);
      print(
          "Scheduling token refresh in ${timeUntilRefresh.inMinutes} minutes");

      _tokenRefreshTimer = Timer(timeUntilRefresh, () async {
        print("Auto-refreshing token before expiration");
        await refreshToken();
      });
    } else {
      // Token is already close to expiry or expired, refresh immediately
      print("Token close to expiry, refreshing now");
      refreshToken();
    }
  }

  // Store user data - updated to also store ID and username separately
  Future<void> storeUserData(User user) async {
    _currentUser = user;
    print(
        "Storing user data for user ID: ${user.id}, username: ${user.username}");

    // Store the whole user object
    await _storage.write(key: USER_DATA_KEY, value: jsonEncode(user.toJson()));

    // Also store ID and username separately for quick access
    if (user.id != null) {
      await _storage.write(key: USER_ID_KEY, value: user.id.toString());
      print("User ID stored separately: ${user.id}");
    }

    if (user.username != null) {
      await _storage.write(key: USERNAME_KEY, value: user.username);
    }
  }

  // Get user data
  Future<User?> getUserData() async {
    if (_currentUser != null) return _currentUser;

    try {
      final userData = await _storage.read(key: USER_DATA_KEY);
      if (userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
        return _currentUser;
      }
    } catch (e) {
      print("Error reading user data: $e");
      // Clear corrupt data
      await _storage.delete(key: USER_DATA_KEY);
    }
    return null;
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: REFRESH_TOKEN_KEY);
    } catch (e) {
      print("Error reading refresh token: $e");
      await _storage.delete(key: REFRESH_TOKEN_KEY);
      return null;
    }
  }

  // Clear all stored data (for logout)
  Future<Map<String, dynamic>> logout() async {
    try {
      // Cancel any token refresh timer
      _tokenRefreshTimer?.cancel();

      // Clear all stored tokens and user data
      await _storage.deleteAll();
      _currentUser = null;

      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      print('Error during logout: $e');
      return {'success': false, 'message': 'Error during logout: $e'};
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
          'Content-Type': 'application/json; charset=utf-8',
          'Accept-Charset': 'utf-8',
        },
        body: jsonEncode(<String, String>{
          'email':
              emailOrUsername, // This field name is actually for either email or username
          'password': password,
        }),
      );

      // Use utf8.decode to properly handle Arabic characters
      final decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> responseData = json.decode(decodedBody);

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

            // Also store ID directly in case storeUserData didn't do it
            if (userData['id'] != null) {
              await _storage.write(
                  key: USER_ID_KEY, value: userData['id'].toString());
              print("User ID stored directly during login: ${userData['id']}");
            }
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

  // Check if access token is expired or will expire soon
  Future<bool> isAccessTokenExpired() async {
    try {
      final expiryStr = await _storage.read(key: TOKEN_EXPIRY_KEY);
      if (expiryStr == null) return true;

      final expiry = DateTime.parse(expiryStr);
      final now = DateTime.now();

      // Consider token expired if it's within buffer time
      return now.isAfter(
          expiry.subtract(Duration(minutes: TOKEN_REFRESH_BUFFER_MINUTES)));
    } catch (e) {
      print('Error checking token expiration: $e');
      return true; // Assume expired on error
    }
  }

  // Refresh token when access token expires
  Future<bool> refreshToken() async {
    final refreshToken = await getRefreshToken();

    if (refreshToken == null) {
      print('No refresh token found');
      return false;
    }

    try {
      print('Attempting to refresh access token');
      final response = await http.post(
        Uri.parse('$_baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Store new access token
        await _storage.write(key: ACCESS_TOKEN_KEY, value: data['access']);

        // Update expiration time (assuming 24 hours)
        final expiryTime = DateTime.now().add(const Duration(hours: 24));
        await _storage.write(
            key: TOKEN_EXPIRY_KEY, value: expiryTime.toIso8601String());

        // Set up new refresh timer
        _setupTokenRefreshTimer(expiryTime);

        print('Successfully refreshed access token');
        return true;
      } else {
        print(
            'Token refresh failed: ${response.statusCode} - ${response.body}');
        // If refresh token is invalid, log the user out
        await logout();
        return false;
      }
    } catch (e) {
      print('Error during token refresh: $e');
      return false;
    }
  }

  // Get current user ID - enhanced with more logging and fallback
  Future<int?> getCurrentUserId() async {
    try {
      // Try reading the ID directly
      final userIdStr = await _storage.read(key: USER_ID_KEY);
      print("Direct USER_ID_KEY read: $userIdStr");

      if (userIdStr != null) {
        try {
          return int.parse(userIdStr);
        } catch (e) {
          print("Error parsing user ID: $e");
        }
      }

      // If ID isn't directly available, try to get it from stored user data
      if (_currentUser?.id != null) {
        print("Using cached current user ID: ${_currentUser!.id}");
        return _currentUser!.id;
      }

      // Try to extract from full user data
      final userData = await _storage.read(key: USER_DATA_KEY);
      if (userData != null) {
        try {
          final userMap = jsonDecode(userData);
          if (userMap.containsKey('id')) {
            final id = userMap['id'];
            print("Extracted user ID from full user data: $id");

            // Store it for future use
            await _storage.write(key: USER_ID_KEY, value: id.toString());

            return id is int ? id : int.parse(id.toString());
          }
        } catch (e) {
          print("Error extracting ID from user data: $e");
        }
      }
    } catch (e) {
      print("Error in getCurrentUserId: $e");
      // Clear corrupt data
      await _storage.delete(key: USER_ID_KEY);
      await _storage.delete(key: USER_DATA_KEY);
    }

    print("Could not retrieve user ID from any source");
    return null;
  }

  // Get current username
  Future<String?> getCurrentUsername() async {
    return await _storage.read(key: USERNAME_KEY);
  }

  // Get access token (refreshes if needed)
  Future<String?> getAccessToken() async {
    try {
      String? accessToken = await _storage.read(key: ACCESS_TOKEN_KEY);

      if (accessToken == null) {
        print('No access token found, attempting to refresh');
        // No access token found, try to refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          accessToken = await _storage.read(key: ACCESS_TOKEN_KEY);
        } else {
          return null; // No valid tokens available
        }
      } else {
        // Check if token is expired or will expire soon
        final isExpired = await isAccessTokenExpired();
        if (isExpired) {
          print('Access token expired or expiring soon, refreshing');
          final refreshed = await refreshToken();
          if (refreshed) {
            accessToken = await _storage.read(key: ACCESS_TOKEN_KEY);
          } else {
            return null;
          }
        }
      }

      return accessToken;
    } catch (e) {
      print('Error getting access token: $e');
      // Clear potentially corrupt token
      await _storage.delete(key: ACCESS_TOKEN_KEY);
      return null;
    }
  }

  // Save user info after login
  Future<void> saveUserInfo(Map<String, dynamic> userData, String accessToken,
      String refreshToken) async {
    await _storage.write(key: ACCESS_TOKEN_KEY, value: accessToken);
    await _storage.write(key: REFRESH_TOKEN_KEY, value: refreshToken);
    await _storage.write(key: USER_ID_KEY, value: userData['id'].toString());
    await _storage.write(key: USERNAME_KEY, value: userData['username']);
  }

  // Debug method to inspect all stored values
  Future<Map<String, String?>> debugInspectStorage() async {
    final Map<String, String?> values = {};
    values[ACCESS_TOKEN_KEY] = await _storage.read(key: ACCESS_TOKEN_KEY);
    values[REFRESH_TOKEN_KEY] = await _storage.read(key: REFRESH_TOKEN_KEY);
    values[USER_DATA_KEY] = await _storage.read(key: USER_DATA_KEY);
    values[USER_ID_KEY] = await _storage.read(key: USER_ID_KEY);
    values[USERNAME_KEY] = await _storage.read(key: USERNAME_KEY);
    values[TOKEN_EXPIRY_KEY] = await _storage.read(key: TOKEN_EXPIRY_KEY);

    print("DEBUG - Stored values:");
    values.forEach((key, value) {
      print(
          "$key: ${value != null ? (key.contains('TOKEN') && !key.contains('EXPIRY') ? '${value.substring(0, 10)}...' : value) : 'null'}");
    });

    return values;
  }

  // Directly set user ID (for testing/fixing)
  Future<void> setCurrentUserId(int id) async {
    await _storage.write(key: USER_ID_KEY, value: id.toString());
    print("Manually set user ID to: $id");
  }

  // Get Firebase authentication token from Django backend
  Future<String?> getFirebaseToken() async {
    try {
      // Make sure we have a valid access token
      final accessToken = await getAccessToken();

      // Use the chat API base URL instead of accounts
      final host = kIsWeb ? '127.0.0.1' : '192.168.1.9';
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

  // Initialize authentication and validate token
  Future<bool> initializeAuth() async {
    try {
      // Check if we have a stored access token
      final accessToken = await _storage.read(key: ACCESS_TOKEN_KEY);
      final expiryStr = await _storage.read(key: TOKEN_EXPIRY_KEY);

      if (accessToken != null) {
        if (expiryStr != null) {
          final expiry = DateTime.parse(expiryStr);
          final now = DateTime.now();

          // If token is expired, try refresh
          if (now.isAfter(expiry)) {
            print("Stored token expired, attempting refresh");
            final refreshed = await refreshToken();
            if (!refreshed) {
              print("Token refresh failed during initialization");
              return false;
            }
          } else {
            // Setup refresh timer for existing token
            _setupTokenRefreshTimer(expiry);
          }
        }

        // We found a token, now try to load the user data
        final userData = await getUserData();

        if (userData != null) {
          print("Found stored session for user: ${userData.username}");
          _currentUser = userData;
          return true; // User is logged in
        }
      }

      return false; // No valid session found
    } catch (e) {
      print("Error initializing auth: $e");
      // If there's an error, clear all stored data to start fresh
      await _handleStorageError();
      return false;
    }
  }

  // Handle storage error by clearing all stored data
  Future<void> _handleStorageError() async {
    print("Handling storage error by clearing all data");
    try {
      await _storage.deleteAll();
      _currentUser = null;
    } catch (e) {
      print("Error clearing storage: $e");
      // Try to delete individual keys
      final keys = [
        ACCESS_TOKEN_KEY,
        REFRESH_TOKEN_KEY,
        USER_DATA_KEY,
        USER_ID_KEY,
        USERNAME_KEY,
        TOKEN_EXPIRY_KEY
      ];

      for (final key in keys) {
        try {
          await _storage.delete(key: key);
        } catch (e) {
          print("Could not delete key $key: $e");
        }
      }
    }
  }

  // Register FCM token with the server
  Future<bool> registerFcmToken(String token) async {
    try {
      final accessToken = await _storage.read(key: ACCESS_TOKEN_KEY);
      if (accessToken == null) {
        print('No access token found, cannot register FCM token');
        return false;
      }

      final host = kIsWeb ? '127.0.0.1' : '192.168.1.9';
      final baseUrl = 'http://$host:8000';
      final response = await http.post(
        Uri.parse('$baseUrl/api/accounts/register-fcm-token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        print('FCM token registered successfully');
        return true;
      } else {
        print('Failed to register FCM token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error registering FCM token: $e');
      return false;
    }
  }
}
