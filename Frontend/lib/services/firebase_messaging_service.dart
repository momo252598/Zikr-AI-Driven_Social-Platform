import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:software_graduation_project/services/notification_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
  
  // Initialize notification service to show notification
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Show notification based on message type
  Map<String, dynamic> data = message.data;
  if (data.containsKey('type') && data['type'] == 'chat_message') {
    // This is a chat message notification
    String senderName = data['senderName'] ?? 'رسالة جديدة';
    String messageContent = data['messageContent'] ?? '';
    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    await notificationService.showMessageNotification(
      id: notificationId,
      senderName: senderName,
      messageContent: messageContent,
      conversationId: data['conversationId'],
    );
  } else if (message.notification != null) {
    // This is a general notification
    await notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? '',
    );
  }
}

class FirebaseMessagingService {
  // Singleton pattern
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  // Services
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  
  // Initialization flag
  bool _isInitialized = false;
  
  // Callback for notification deduplication
  Function(String messageId)? _notificationReceivedCallback;
  
  // Set callback to be notified when an FCM message is received
  void setNotificationReceivedCallback(Function(String messageId) callback) {
    _notificationReceivedCallback = callback;
  }
  
  // Get FCM token for the device
  Future<String?> get token => _messaging.getToken();
  
  // Initialize FCM
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize notifications service first
    await _notificationService.initialize();
    
    debugPrint('Initializing Firebase Messaging Service...');
    
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Request permission for iOS and web
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    
    // Get FCM token
    String? token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
    
    // Register token with backend
    if (token != null) {
      await registerTokenWithBackend(token);
    }
    
    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      registerTokenWithBackend(newToken);
    });
    
    // Handle incoming messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Check if the app was opened from a notification when it was terminated
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
    
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
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message in the foreground!');
    debugPrint('Message data: ${message.data}');
    
    // Notify about received FCM message for deduplication
    if (message.messageId != null && _notificationReceivedCallback != null) {
      _notificationReceivedCallback!(message.messageId!);
    }
    
    if (message.notification != null) {
      debugPrint('Message also contained a notification:');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      
      // Show the notification using our notification service
      _showMessageNotification(message);
    }
  }
  
  // Show notification from FCM message
  Future<void> _showMessageNotification(RemoteMessage message) async {
    // Extract data from the message
    final notification = message.notification;
    final data = message.data;
    
    // Check if it's a chat message notification
    if (data.containsKey('type') && data['type'] == 'chat_message') {
      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      String senderName = data['senderName'] ?? 'رسالة جديدة';
      String messageContent = data['messageContent'] ?? '';
      String conversationId = data['conversationId'] ?? '';
      
      // Show the notification with the message content
      await _notificationService.showMessageNotification(
        id: notificationId,
        senderName: senderName,
        messageContent: messageContent,
        conversationId: conversationId,
      );
    } else {
      // Handle general notifications
      if (notification != null) {
        final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
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
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from a notification!');
    debugPrint('Message data: ${message.data}');
    
    // Notify about received FCM message for deduplication
    if (message.messageId != null && _notificationReceivedCallback != null) {
      _notificationReceivedCallback!(message.messageId!);
    }
    
    // TODO: Navigate to the appropriate screen based on the notification data
    // For example, if it's a chat message, navigate to the chat page
  }
  
  // Handle initial message (app opened from terminated state)
  void _handleInitialMessage(RemoteMessage message) {
    debugPrint('App started from a notification when it was terminated!');
    debugPrint('Message data: ${message.data}');
    
    // Notify about received FCM message for deduplication
    if (message.messageId != null && _notificationReceivedCallback != null) {
      _notificationReceivedCallback!(message.messageId!);
    }
    
    // TODO: Similar to _handleMessageOpenedApp, navigate based on notification data
    // But this should be called after the app has initialized
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
}