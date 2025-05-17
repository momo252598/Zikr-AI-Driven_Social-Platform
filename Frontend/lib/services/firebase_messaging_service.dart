import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_graduation_project/services/notification_service.dart'
    as notification_service;
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/services/chat_notification_helper.dart';

// Add logging to track all notification-related handlers
// Handle background messages
// Ensure Firebase is initialized only once in the background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(
      '[BACKGROUND HANDLER] Triggered for message: ${message.messageId}');

  final String? messageId = message.messageId;
  if (messageId != null) {
    final prefs = await SharedPreferences.getInstance();

    // Check if this message was already processed by the foreground handler
    final foregroundProcessedIds =
        prefs.getStringList('foreground_processed_ids') ?? [];
    if (foregroundProcessedIds.contains(messageId)) {
      debugPrint(
          '[BACKGROUND HANDLER] Message already processed by foreground handler, skipping: $messageId');
      return;
    }

    // Check if this message was already processed by this background handler
    final processedMessageIds =
        prefs.getStringList('processed_message_ids') ?? [];

    if (processedMessageIds.contains(messageId)) {
      debugPrint(
          '[BACKGROUND HANDLER] Duplicate message detected, skipping: $messageId');
      return;
    }

    // Add a check for recently shown notifications with similar content
    try {
      final data = message.data;
      if (data.containsKey('type') && data['type'] == 'chat_message') {
        final conversationId = data['conversationId'] ?? '';
        final messageContent = data['messageContent'] ?? '';

        // Check if we've already shown a similar notification
        final lastNotificationKey = 'last_notification_$conversationId';
        final lastNotificationData = prefs.getString(lastNotificationKey);

        if (lastNotificationData != null) {
          try {
            final lastData = json.decode(lastNotificationData);
            final lastTimestamp = lastData['timestamp'] as int?;
            final lastMessage = lastData['message'] as String?;

            if (lastTimestamp != null && lastMessage != null) {
              final now = DateTime.now().millisecondsSinceEpoch;
              if (now - lastTimestamp < 5000 && lastMessage == messageContent) {
                debugPrint(
                    '[BACKGROUND HANDLER] Similar notification shown recently, skipping');
                return;
              }
            }
          } catch (e) {
            // Ignore JSON parsing errors
          }
        }
      }
    } catch (e) {
      debugPrint(
          '[BACKGROUND HANDLER] Error checking for similar notifications: $e');
    }

    processedMessageIds.add(messageId);
    if (processedMessageIds.length > 100) {
      processedMessageIds.removeAt(0);
    }
    await prefs.setStringList('processed_message_ids', processedMessageIds);
  }

  // Use the imported NotificationService
  final notificationService = notification_service.NotificationService();
  await notificationService.initialize();

  Map<String, dynamic> data = message.data;
  int notificationIdBase = messageId != null
      ? messageId.hashCode
      : DateTime.now().millisecondsSinceEpoch ~/ 1000;
  if (data.containsKey('type') && data['type'] == 'chat_message') {
    String conversationId = data['conversationId'] ?? '';
    String senderName = data['senderName'] ?? 'رسالة جديدة';
    String messageContent = data['messageContent'] ?? '';

    // Check if user is in this conversation
    final chatNotificationHelper = ChatNotificationHelper();
    if (chatNotificationHelper.isInConversation(conversationId)) {
      debugPrint(
          'User is in conversation $conversationId, skipping background notification');
      return;
    } // Check for duplicate notifications with similar content in the last 5 seconds
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final lastNotificationKey = 'last_notification_$conversationId';
      final lastNotificationData = prefs.getString(lastNotificationKey);

      if (lastNotificationData != null) {
        try {
          final lastData = json.decode(lastNotificationData);
          final lastTimestamp = lastData['timestamp'] as int?;
          final lastMessage = lastData['message'] as String?;

          if (lastTimestamp != null && lastMessage != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - lastTimestamp < 5000 && lastMessage == messageContent) {
              debugPrint(
                  '[BACKGROUND HANDLER] Similar notification shown recently, skipping');
              return;
            }
          }
        } catch (e) {
          // Ignore JSON parsing errors
        }
      }

      // Store this notification data to prevent duplicates
      await prefs.setString(
          lastNotificationKey,
          json.encode({
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'message': messageContent,
          }));
    } catch (e) {
      debugPrint(
          '[BACKGROUND HANDLER] Error checking for similar notifications: $e');
    }
    debugPrint(
        '[BACKGROUND HANDLER] Showing chat message notification: $messageId');
    // Make sure to show the notification with high visibility for background messages
    await notificationService.showMessageNotification(
      id: notificationIdBase,
      senderName: senderName,
      messageContent: messageContent,
      conversationId: conversationId,
    );
    return;
  } else if (message.notification != null) {
    debugPrint(
        'Showing general notification in background handler: $messageId');
    await notificationService.showNotification(
      id: notificationIdBase,
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? '',
    );
  }
}

class FirebaseMessagingService {
  // Singleton pattern
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();
  // Services
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final notification_service.NotificationService _notificationService =
      notification_service.NotificationService();
  final AuthService _authService = AuthService();

  // Initialization flag
  bool _isInitialized = false;
  // Storage for pending navigation after notification tap
  Map<String, dynamic>? _notificationNavigationData;

  // Callback for notification deduplication
  Function(String messageId)? _notificationReceivedCallback;

  // Set of processed message IDs for deduplication (in-memory)
  final Set<String> _foregroundProcessedMessageIds = {};

  // Track current app state
  AppLifecycleState _appState = AppLifecycleState.resumed;

  // Set current app lifecycle state
  void setAppState(AppLifecycleState state) {
    _appState = state;
    debugPrint('[FirebaseMessagingService] App state set to $_appState');
  }

  // Set callback to be notified when an FCM message is received
  void setNotificationReceivedCallback(Function(String messageId) callback) {
    _notificationReceivedCallback = callback;
  }

  // Function to navigate to a chat when a notification is tapped
  void navigateToChat(String conversationId) {
    // We'll store the conversation ID to be handled by the app
    debugPrint('Storing conversation ID for navigation: $conversationId');
    _notificationNavigationData = {
      'type': 'chat',
      'conversationId': conversationId
    };
  }

  // Get and clear pending navigation data
  Map<String, dynamic>? getAndClearNotificationNavigation() {
    final data = _notificationNavigationData;
    _notificationNavigationData = null;
    return data;
  } // Get FCM token for the device

  Future<String?> get token async {
    try {
      // For web, we need to handle VAPID key differently
      if (kIsWeb) {
        // For Web, we need to use vapidKey to get a token
        return await getWebToken();
      }
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error retrieving FCM token: $e');
      return null;
    }
  }

  // Get web specific FCM token with VAPID key
  Future<String?> getWebToken() async {
    try {
      // Replace this with your actual VAPID key from Firebase Console
      // You can get this from Firebase Console > Project Settings > Cloud Messaging > Web Configuration > Web Push certificates
      const String vapidKey =
          "BDPXEz_nnIvgKrKiyl5RQh7iqQmOx4qBTO2_YA3kPge5Sii4ZUNVAOu_gQus-4IBzVDk6OeVwJm8pVXZ-LMRaec";

      debugPrint('Requesting FCM token for web with VAPID key');
      return await _messaging.getToken(vapidKey: vapidKey);
    } catch (e) {
      debugPrint('Error retrieving web FCM token: $e');
      // Handle the error gracefully so it doesn't crash the application
      return null;
    }
  }

  // Initialize FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize notifications service first
    await _notificationService.initialize();

    debugPrint('Initializing Firebase Messaging Service...');

    // Clean up old message IDs to prevent excessive storage usage
    await _cleanupOldMessageIds();

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission for iOS and web
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
        'User granted permission: ${settings.authorizationStatus}'); // Get FCM token
    String? token;
    try {
      // Get token (platform-specific implementation is in the getter)
      token = await this.token;
      debugPrint('FCM Token: $token');

      // Register token with backend
      if (token != null) {
        await registerTokenWithBackend(token);
      }
    } catch (e) {
      debugPrint('Error during FCM initialization: $e');
    } // Common setup for all platforms
    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      registerTokenWithBackend(newToken);
    });

    // Handle incoming messages when the app is in the foreground - works on all platforms
    FirebaseMessaging.onMessage.listen((message) {
      if (kIsWeb) {
        // Web-specific handling
        debugPrint('Received web foreground message: ${message.messageId}');
        _handleSimplifiedWebMessage(message);
      } else {
        // Native platform handling
        _handleForegroundMessage(message);
      }
    });

    // Platform-specific setup
    if (!kIsWeb) {
      // Native platform only features
      // Handle when the app is opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if the app was opened from a notification when it was terminated
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleInitialMessage(initialMessage);
      }
    } else {
      // Web-specific setup
      debugPrint('Web platform detected, configuring web notifications');

      // Request permission for web notifications
      try {
        // This ensures the service worker is properly registered
        final settings = await _messaging.requestPermission();
        debugPrint(
            'Web notification permission status: ${settings.authorizationStatus}');

        // Get the token for web
        final webToken = await getWebToken();
        debugPrint('Web FCM token: $webToken');

        if (webToken != null) {
          await registerTokenWithBackend(webToken);
        }
      } catch (e) {
        debugPrint('Error setting up web notifications: $e');
      }
    }

    // Schedule periodic cleanup of old message IDs
    Timer.periodic(Duration(hours: 12), (_) => _cleanupOldMessageIds());

    _isInitialized = true;
    debugPrint('Firebase Messaging Service initialized successfully');
  }

  // Register FCM token with backend
  Future<void> registerTokenWithBackend(String token) async {
    try {
      // Check if user is logged in before registering token
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint('User not logged in, skipping FCM token registration');
        return;
      }

      // Register token with backend
      final success = await _authService.registerFcmToken(token);
      if (success) {
        debugPrint('FCM token registered with backend successfully');
      } else {
        debugPrint('Failed to register FCM token with backend');
      }
    } catch (e) {
      debugPrint('Error registering FCM token with backend: $e');
    }
  }

  // Handle messages received in the foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
        '[FirebaseMessagingService] Foreground handler triggered for message: ${message.messageId}, App state: $_appState');

    final String? messageId = message.messageId;
    if (messageId != null) {
      // First check in-memory cache for fast rejection
      if (_foregroundProcessedMessageIds.contains(messageId)) {
        debugPrint(
            '[FirebaseMessagingService] Duplicate message detected in foreground memory, skipping: $messageId');
        return;
      }

      // Then check in shared preferences
      final prefs = await SharedPreferences.getInstance();
      final processedMessageIds =
          prefs.getStringList('processed_message_ids') ?? [];

      if (processedMessageIds.contains(messageId)) {
        debugPrint(
            '[FirebaseMessagingService] Duplicate message detected in SharedPreferences, skipping: $messageId');
        return;
      }

      // Mark as processed in memory cache
      _foregroundProcessedMessageIds.add(messageId);

      // Mark as processed in persistent storage for background handler
      processedMessageIds.add(messageId);
      if (processedMessageIds.length > 100) {
        processedMessageIds.removeAt(0);
      }
      await prefs.setStringList('processed_message_ids', processedMessageIds);

      // Only add to foreground list if we're actually in foreground to prevent conflicts
      // This will let background handler handle notifications when app is in background
      if (_appState == AppLifecycleState.resumed) {
        debugPrint(
            '[FirebaseMessagingService] App is in foreground, handling notification directly');
        final foregroundProcessedIds =
            prefs.getStringList('foreground_processed_ids') ?? [];
        foregroundProcessedIds.add(messageId);
        if (foregroundProcessedIds.length > 100) {
          foregroundProcessedIds.removeAt(0);
        }
        await prefs.setStringList(
            'foreground_processed_ids', foregroundProcessedIds);
      } else {
        // For non-foreground states, let the background handler display the notification
        debugPrint(
            '[FirebaseMessagingService] App is NOT in foreground, letting background handler show notification');
        return;
      }

      // Clean up memory cache after delay
      Future.delayed(Duration(seconds: 30), () {
        _foregroundProcessedMessageIds.remove(messageId);
      });
    }

    int notificationIdBase = messageId != null
        ? messageId.hashCode
        : DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final data = message.data;

    if (data.containsKey('type') && data['type'] == 'chat_message') {
      final conversationId = data['conversationId'];
      final chatNotificationHelper = ChatNotificationHelper();

      if (chatNotificationHelper.isInConversation(conversationId)) {
        debugPrint(
            'User is in conversation $conversationId, skipping notification');
        return;
      }

      final String senderName = data['senderName'] ?? 'رسالة جديدة';
      final String messageContent = data['messageContent'] ?? '';
      debugPrint(
          'Showing chat message notification in foreground handler: $messageId');

      await _notificationService.showMessageNotification(
        id: notificationIdBase,
        senderName: senderName,
        messageContent: messageContent,
        conversationId: conversationId,
      );
      return;
    }

    if (message.notification != null) {
      debugPrint(
          'Showing general notification in foreground handler: $messageId');
      await _showNotificationWithConsistentId(message, notificationIdBase);
    }
  }

  // Show notification with consistent ID based on message ID
  Future<void> _showNotificationWithConsistentId(
      RemoteMessage message, int notificationId) async {
    // Extract data from the message
    final notification = message.notification;
    final data = message.data;

    // Check if it's a chat message notification
    if (data.containsKey('type') && data['type'] == 'chat_message') {
      String senderName = data['senderName'] ?? 'رسالة جديدة';
      String messageContent = data['messageContent'] ?? '';
      String conversationId = data['conversationId'] ?? '';

      // Show the notification with the message content using consistent ID
      await _notificationService.showMessageNotification(
        id: notificationId,
        senderName: senderName,
        messageContent: messageContent,
        conversationId: conversationId,
      );
    } else {
      // Handle general notifications
      if (notification != null) {
        await _notificationService.showNotification(
          id: notificationId,
          title: notification.title ?? 'إشعار جديد',
          body: notification.body ?? '',
          payload: json.encode(data),
        );
      }
    }
  }

  // Handle message when the app is opened from a notification
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint(
        'Message opened app handler triggered for message: ${message.messageId}');

    // Check for duplicate handling using shared preferences for persistent tracking
    final messageId = message.messageId;
    if (messageId != null) {
      // First check in-memory cache
      if (_foregroundProcessedMessageIds.contains(messageId)) {
        debugPrint(
            'Already processed this opened message (in-memory), skipping duplicate handling: $messageId');
        return;
      }

      // Then check in shared preferences
      final prefs = await SharedPreferences.getInstance();
      final processedNavigationMessageIds =
          prefs.getStringList('processed_navigation_message_ids') ?? [];

      if (processedNavigationMessageIds.contains(messageId)) {
        debugPrint(
            'Already navigated for this message (in SharedPreferences), skipping: $messageId');
        return;
      }

      // Add to processed navigation list
      processedNavigationMessageIds.add(messageId);
      if (processedNavigationMessageIds.length > 50) {
        processedNavigationMessageIds.removeAt(0); // Remove oldest
      }
      await prefs.setStringList(
          'processed_navigation_message_ids', processedNavigationMessageIds);

      // Also track in memory
      _foregroundProcessedMessageIds.add(messageId);
      Future.delayed(Duration(seconds: 30), () {
        _foregroundProcessedMessageIds.remove(messageId);
      });
    }

    // Notify about received FCM message for deduplication
    if (message.messageId != null && _notificationReceivedCallback != null) {
      _notificationReceivedCallback!(message.messageId!);
    }

    // Handle navigation for chat messages - look in both data and notification
    String? conversationId;

    // First check the data part (priority)
    if (message.data.containsKey('type') &&
        message.data['type'] == 'chat_message') {
      conversationId = message.data['conversationId'];
    }

    // If we found a conversation ID, navigate to it
    if (conversationId != null) {
      debugPrint('Navigating to conversation from opened app: $conversationId');
      navigateToChat(conversationId);
    }
  }

  // Handle initial message (app opened from terminated state)
  Future<void> _handleInitialMessage(RemoteMessage message) async {
    debugPrint(
        'Initial message handler triggered for message: ${message.messageId}');

    // Check for duplicate handling using shared preferences for persistent tracking
    final messageId = message.messageId;
    if (messageId != null) {
      // Check if we've already processed this message for navigation
      final prefs = await SharedPreferences.getInstance();
      final processedNavigationMessageIds =
          prefs.getStringList('processed_navigation_message_ids') ?? [];

      if (processedNavigationMessageIds.contains(messageId)) {
        debugPrint(
            'Already navigated for this initial message, skipping: $messageId');
        return;
      }

      // Add to processed navigation list
      processedNavigationMessageIds.add(messageId);
      if (processedNavigationMessageIds.length > 50) {
        processedNavigationMessageIds.removeAt(0); // Remove oldest
      }
      await prefs.setStringList(
          'processed_navigation_message_ids', processedNavigationMessageIds);

      // Also track in memory
      _foregroundProcessedMessageIds.add(messageId);
      Future.delayed(Duration(seconds: 30), () {
        _foregroundProcessedMessageIds.remove(messageId);
      });
    }

    // Notify about received FCM message for deduplication
    if (message.messageId != null && _notificationReceivedCallback != null) {
      _notificationReceivedCallback!(message.messageId!);
    }

    // Handle navigation for chat messages - look in both data and notification
    String? conversationId;

    // First check the data part (priority)
    if (message.data.containsKey('type') &&
        message.data['type'] == 'chat_message') {
      conversationId = message.data['conversationId'];
    }

    // If we found a conversation ID, navigate to it
    if (conversationId != null) {
      debugPrint(
          'Navigating to conversation from initial message: $conversationId');
      navigateToChat(conversationId);
    }
  }

  // Subscribe to a topic for receiving broadcasts
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  // Clean up old message IDs to prevent excessive storage usage
  Future<void> _cleanupOldMessageIds() async {
    try {
      debugPrint('Cleaning up old message IDs...');
      final prefs = await SharedPreferences.getInstance();

      // Clean up old notification tracking data
      final allKeys = prefs.getKeys();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final key in allKeys) {
        if (key.startsWith('last_notification_')) {
          try {
            final data = json.decode(prefs.getString(key) ?? '{}');
            final timestamp = data['timestamp'] as int? ?? 0;
            // Remove notification records older than 1 hour
            if (now - timestamp > 3600000) {
              await prefs.remove(key);
              debugPrint('Removed old notification record: $key');
            }
          } catch (e) {
            // If there's an error, just remove the key
            await prefs.remove(key);
          }
        }
      }

      // Clean up foreground processed IDs (keep only the latest 50)
      final foregroundProcessedIds =
          prefs.getStringList('foreground_processed_ids') ?? [];
      if (foregroundProcessedIds.length > 50) {
        final newForegroundList =
            foregroundProcessedIds.sublist(foregroundProcessedIds.length - 50);
        await prefs.setStringList(
            'foreground_processed_ids', newForegroundList);
        debugPrint(
            'Trimmed foreground_processed_ids from ${foregroundProcessedIds.length} to ${newForegroundList.length}');
      }

      // Clean up processed message IDs (keep only the latest 50)
      final processedMessageIds =
          prefs.getStringList('processed_message_ids') ?? [];
      if (processedMessageIds.length > 50) {
        final newList =
            processedMessageIds.sublist(processedMessageIds.length - 50);
        await prefs.setStringList('processed_message_ids', newList);
        debugPrint(
            'Trimmed processed_message_ids from ${processedMessageIds.length} to ${newList.length}');
      }

      // Clean up navigation message IDs (keep only the latest 20)
      final navMessageIds =
          prefs.getStringList('processed_navigation_message_ids') ?? [];
      if (navMessageIds.length > 20) {
        final newNavList = navMessageIds.sublist(navMessageIds.length - 20);
        await prefs.setStringList(
            'processed_navigation_message_ids', newNavList);
        debugPrint(
            'Trimmed processed_navigation_message_ids from ${navMessageIds.length} to ${newNavList.length}');
      }
    } catch (e) {
      debugPrint('Error cleaning up message IDs: $e');
    }
  }

  // Handle messages specifically for web platform
  Future<void> _handleSimplifiedWebMessage(RemoteMessage message) async {
    debugPrint(
        '[FirebaseMessagingService] Web message handler: ${message.messageId}');

    // Skip duplicate detection for web to simplify implementation
    try {
      // Extract message data
      Map<String, dynamic> data = message.data;

      // Process based on message type
      if (data.containsKey('type')) {
        String type = data['type'] as String;

        if (type == 'chat_message') {
          String senderName = data['senderName'] ?? 'رسالة جديدة';
          String messageContent = data['messageContent'] ?? '';
          String conversationId = data['conversationId'] ?? '';

          debugPrint(
              '[Web] Chat message: $senderName - $messageContent ($conversationId)');

          // Just update UI if needed, skip actual native notifications on web
          // Web browsers handle their own notification permissions and display
        }
      }

      debugPrint('[Web] Message processed: ${message.messageId}');
    } catch (e) {
      debugPrint('[Web] Error processing message: $e');
    }
  }
}
