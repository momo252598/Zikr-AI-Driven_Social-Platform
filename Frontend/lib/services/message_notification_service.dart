import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_graduation_project/services/notification_service.dart';
import 'package:software_graduation_project/services/firebase_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/utils/text_utils.dart';
import 'package:firebase_database/firebase_database.dart';

class MessageNotificationService {
  // Singleton pattern
  static final MessageNotificationService _instance = MessageNotificationService._internal();
  factory MessageNotificationService() => _instance;
  MessageNotificationService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  
  // Keep track of active subscriptions
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  
  // Track the last message timestamp shown for each conversation
  final Map<String, int> _lastMessageTimestamps = {};
  
  // Track current user ID to prevent sending notifications for own messages
  int? _currentUserId;
  
  // Flag to track if the notifications are already initialized
  bool _isInitialized = false;
  
  // Flag to track app state
  AppLifecycleState _appState = AppLifecycleState.resumed;

  // Initialize the service and request notification permissions
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    // Initialize the notification service
    await _notificationService.initialize();

    // Get the current user ID
    _currentUserId = await _authService.getCurrentUserId();
    
    // Load the last message timestamps
    await _loadLastMessageTimestamps();
    
    _isInitialized = true;
    debugPrint('Message notification service initialized, user ID: $_currentUserId');
    return true;
  }
  
  // Set current app lifecycle state
  void setAppState(AppLifecycleState state) {
    _appState = state;
    debugPrint('Message notification service: App state set to $_appState');
  }
  
  // Load last message timestamps from SharedPreferences
  Future<void> _loadLastMessageTimestamps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      for (final key in allKeys) {
        if (key.startsWith('last_msg_ts_')) {
          final conversationId = key.replaceFirst('last_msg_ts_', '');
          final timestamp = prefs.getInt(key);
          if (timestamp != null) {
            _lastMessageTimestamps[conversationId] = timestamp;
          }
        }
      }
      
      debugPrint('Loaded ${_lastMessageTimestamps.length} last message timestamps');
    } catch (e) {
      debugPrint('Error loading last message timestamps: $e');
    }
  }
  
  // Save last message timestamp for a conversation
  Future<void> _saveLastMessageTimestamp(String conversationId, int timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_msg_ts_$conversationId', timestamp);
      debugPrint('Saved last message timestamp for conversation $conversationId: $timestamp');
    } catch (e) {
      debugPrint('Error saving last message timestamp: $e');
    }
  }
  
  // Check and request notification permissions if needed
  Future<bool> ensurePermissions({BuildContext? context}) async {
    // First check existing permissions
    bool hasPermissions = await _notificationService.checkPermissions();
    
    if (!hasPermissions && context != null) {
      // Request permissions if needed and context is provided
      hasPermissions = await _notificationService.requestPermissions(context: context);
    }
    
    return hasPermissions;
  }

  // Subscribe to messages for a specific conversation using direct Firebase approach
  Future<void> subscribeToConversation(String conversationId, String contactName) async {
    await initialize();
    
    // Don't subscribe twice to the same conversation
    if (_messageSubscriptions.containsKey(conversationId)) {
      debugPrint('Already subscribed to conversation $conversationId');
      return;
    }
    
    debugPrint('Subscribing to notifications for conversation: $conversationId');
    
    // Get a direct reference to the Firebase database node for this conversation
    final DatabaseReference messagesRef = FirebaseDatabase.instance
        .ref()
        .child('chats')
        .child(conversationId)
        .child('messages');
    
    // Listen for the LAST child added event only 
    // This will only fire when a new message is added
    final subscription = messagesRef.limitToLast(1).onChildAdded.listen(
      (event) async {
        if (_currentUserId == null || event.snapshot.value == null) return;
        
        try {
          // Get the message data
          final messageData = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
          
          // Process the message for notification if needed
          await _processMessage(conversationId, contactName, messageData);
        } catch (e) {
          debugPrint('Error processing message for notifications: $e');
        }
      },
      onError: (error) {
        debugPrint('Error in message subscription: $error');
      }
    );
    
    // Store the subscription for later cleanup
    _messageSubscriptions[conversationId] = subscription;
  }
  
  // Process a message for notification
  Future<void> _processMessage(
    String conversationId, 
    String contactName, 
    Map<dynamic, dynamic> messageData
  ) async {
    // Get message timestamp
    final timestamp = _parseMessageTimestamp(messageData);
    
    // If we couldn't get a valid timestamp, skip this message
    if (timestamp == 0) return;
    
    // Get the last timestamp we showed a notification for
    final lastTimestamp = _lastMessageTimestamps[conversationId] ?? 0;
    
    // If this message is older or the same as our last notification, skip it
    // We add a 5 second buffer for background mode to avoid duplicates
    if (_appState != AppLifecycleState.resumed) {
      // Be extra strict in background mode
      if (timestamp <= lastTimestamp) {
        debugPrint('Skipping notification for old or duplicate message (background mode)');
        return;
      }
    } else {
      // In foreground mode, allow closer timestamps
      if (timestamp <= lastTimestamp) {
        debugPrint('Skipping notification for old or duplicate message');
        return;
      }
    }
    
    // Check if this is a message from someone else (not the current user)
    final senderId = messageData['sender_id']?.toString() ?? '';
    final currentUserIdStr = _currentUserId.toString();
    
    if (senderId.isEmpty || senderId == currentUserIdStr) {
      // Skip our own messages
      return;
    }
    
    // Check if the message is already read
    final readBy = messageData['read_by'] as Map?;
    final isRead = readBy != null && readBy[currentUserIdStr] == true;
    if (isRead) {
      // Skip already read messages
      return;
    }
    
    // Get the sender name
    String senderName = contactName;
    if (messageData.containsKey('sender_username')) {
      senderName = messageData['sender_username'] ?? contactName;
    }
    
    // Get the message content and fix any Arabic encoding issues
    String messageContent = TextUtils.fixArabicEncoding(
      messageData['content'] ?? 'رسالة جديدة'
    );
    
    // Generate a unique ID for this notification
    final notificationId = timestamp.hashCode;
    
    // Show the notification
    await _notificationService.showMessageNotification(
      id: notificationId,
      senderName: senderName,
      messageContent: messageContent,
      conversationId: conversationId,
    );
    
    // Update the last notification timestamp for this conversation
    _lastMessageTimestamps[conversationId] = timestamp;
    
    // Save this timestamp to persistent storage
    await _saveLastMessageTimestamp(conversationId, timestamp);
    
    debugPrint('Notification sent for message from $senderName in conversation $conversationId');
  }
  
  // Parse timestamp from message data
  int _parseMessageTimestamp(Map<dynamic, dynamic> messageData) {
    // Try to get the timestamp field
    if (messageData.containsKey('timestamp')) {
      final timestampValue = messageData['timestamp'];
      
      // Handle different timestamp formats
      if (timestampValue is int) {
        return timestampValue;
      } else if (timestampValue is String) {
        return int.tryParse(timestampValue) ?? 0;
      }
    }
    
    // If we couldn't get a valid timestamp, use current time as fallback
    return DateTime.now().millisecondsSinceEpoch;
  }
  
  // Unsubscribe from a specific conversation
  void unsubscribeFromConversation(String conversationId) {
    final subscription = _messageSubscriptions[conversationId];
    if (subscription != null) {
      subscription.cancel();
      _messageSubscriptions.remove(conversationId);
      debugPrint('Unsubscribed from notifications for conversation: $conversationId');
    }
  }
  
  // Unsubscribe from all conversations
  void unsubscribeAll() {
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();
    debugPrint('Unsubscribed from all conversation notifications');
  }
}