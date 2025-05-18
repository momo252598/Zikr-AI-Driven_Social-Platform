import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_graduation_project/services/notification_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';

class SocialNotificationService {
  // Singleton pattern
  static final SocialNotificationService _instance =
      SocialNotificationService._internal();
  factory SocialNotificationService() => _instance;
  SocialNotificationService._internal();

  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  // Track current user ID to prevent sending notifications for own actions
  int? _currentUserId;

  // Flag to track if the service is initialized
  bool _isInitialized = false;

  // Flag to track app state
  AppLifecycleState _appState = AppLifecycleState.resumed;

  // Init method
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Initialize notification service
    await _notificationService.initialize();

    // Get current user ID
    _currentUserId = await _authService.getCurrentUserId();

    _isInitialized = true;
    debugPrint(
        'Social notification service initialized, user ID: $_currentUserId');
    return true;
  }

  // Set current app lifecycle state
  void setAppState(AppLifecycleState state) {
    _appState = state;
    debugPrint('Social notification service: App state set to $_appState');
  }

  // Process social notification from FCM
  Future<void> handleSocialNotification(Map<String, dynamic> data,
      {bool fromTap = false}) async {
    // Extract notification data
    final String notificationType = data['notificationType'] ?? '';
    final String senderName = data['senderName'] ?? '';
    final String postContent = data['postContent'] ?? '';
    final String senderId = data['senderId'] ?? '';
    final String postId = data['postId'] ?? '';

    debugPrint(
        'Processing social notification: $notificationType from $senderName (fromTap: $fromTap)');

    // Only store notification data if it came from a tap or the app is not in foreground
    // This prevents automatic navigation when receiving a foreground notification
    if (fromTap || _appState != AppLifecycleState.resumed) {
      // Store the sender ID and post ID for navigation when user taps the notification
      await _storeNotificationData(
          notificationType, senderId, postId, senderName);
    } else {
      debugPrint('App is in foreground, not storing navigation data');
    }

    // No need to show a notification here as FCM will handle it for background notifications
    // and FirebaseMessagingService will handle foreground notifications
  }

  // Store notification data for later navigation
  Future<void> _storeNotificationData(String notificationType, String senderId,
      String postId, String senderName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('social_notification_type', notificationType);
      await prefs.setString('social_notification_sender_id', senderId);
      await prefs.setString('social_notification_post_id', postId);
      await prefs.setString('social_notification_sender_name', senderName);
      await prefs.setInt('social_notification_timestamp',
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error storing social notification data: $e');
    }
  }

  // Retrieve stored notification data for navigation
  Future<Map<String, dynamic>?> getLastNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final notificationType = prefs.getString('social_notification_type');
      final senderId = prefs.getString('social_notification_sender_id');
      final postId = prefs.getString('social_notification_post_id');
      final senderName = prefs.getString('social_notification_sender_name');
      final timestamp = prefs.getInt('social_notification_timestamp');

      // Return null if any key components are missing
      if (notificationType == null || senderId == null || postId == null) {
        return null;
      }

      // Only return recent notifications (within the last hour)
      final now = DateTime.now().millisecondsSinceEpoch;
      if (timestamp != null && now - timestamp > 3600000) {
        // 1 hour in milliseconds
        return null;
      }

      return {
        'notificationType': notificationType,
        'senderId': senderId,
        'postId': postId,
        'senderName': senderName,
        'timestamp': timestamp,
      };
    } catch (e) {
      debugPrint('Error retrieving social notification data: $e');
      return null;
    }
  }

  // Clear stored notification data after navigation
  Future<void> clearNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('social_notification_type');
      await prefs.remove('social_notification_sender_id');
      await prefs.remove('social_notification_post_id');
      await prefs.remove('social_notification_sender_name');
      await prefs.remove('social_notification_timestamp');
    } catch (e) {
      debugPrint('Error clearing social notification data: $e');
    }
  }
}
