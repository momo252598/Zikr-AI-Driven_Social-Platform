import 'dart:async';
import 'package:flutter/material.dart';
import 'package:software_graduation_project/services/notification_service.dart';
import 'package:software_graduation_project/services/message_notification_service.dart';
import 'package:software_graduation_project/services/chat_api_service.dart';
import 'package:software_graduation_project/services/firebase_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';

/// A global manager for handling all types of notifications in the app
class GlobalNotificationManager {
  // Singleton pattern
  static final GlobalNotificationManager _instance =
      GlobalNotificationManager._internal();
  factory GlobalNotificationManager() => _instance;
  GlobalNotificationManager._internal();

  // Services
  final NotificationService _notificationService = NotificationService();
  final MessageNotificationService _messageNotificationService =
      MessageNotificationService();
  final ChatApiService _chatApiService = ChatApiService();
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  // State tracking
  bool _isInitialized = false;
  Timer? _conversationRefreshTimer;
  int _activeConversationId = -1; // Track currently open conversation

  // Initialize the manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize notification services
    await _notificationService.initialize();
    await _messageNotificationService.initialize();

    // Start periodic refresh for conversations
    _startConversationRefreshCycle();

    _isInitialized = true;
    debugPrint('GlobalNotificationManager initialized');
  }

  // Request permissions for notifications
  Future<bool> requestNotificationPermissions(BuildContext context) async {
    return await _notificationService.requestPermissions(context: context);
  }

  // Set the active conversation ID (to avoid notifications for active chats)
  void setActiveConversationId(int conversationId) {
    _activeConversationId = conversationId;
    debugPrint('Active conversation set to: $conversationId');
  }

  // Clear active conversation when user leaves chat
  void clearActiveConversation() {
    _activeConversationId = -1;
    debugPrint('Active conversation cleared');
  }

  // Periodically refresh conversation subscriptions
  void _startConversationRefreshCycle() {
    // Cancel any existing timer
    _conversationRefreshTimer?.cancel();

    // Initial fetch
    _refreshConversationSubscriptions();

    // Set up a periodic refresh every 2 minutes
    _conversationRefreshTimer = Timer.periodic(
        const Duration(minutes: 2), (_) => _refreshConversationSubscriptions());
  }

  // Fetch all conversations and subscribe to their notifications
  Future<void> _refreshConversationSubscriptions() async {
    try {
      // Make sure user is authenticated
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        debugPrint('User not authenticated, skipping conversation refresh');
        return;
      }

      // Fetch all conversations for the user
      final conversations = await _chatApiService.getConversations();

      // Unsubscribe from all previous conversations
      _messageNotificationService.unsubscribeAll();

      // Subscribe to each conversation except the active one
      for (final conversation in conversations) {
        final conversationId = conversation['id'];
        final firebaseId = conversation['firebase_id']?.toString();

        // Skip the active conversation
        if (conversationId == _activeConversationId) {
          debugPrint('Skipping active conversation: $conversationId');
          continue;
        }

        // Get contact name for the notification
        String contactName = conversation['name'] ?? 'محادثة';

        // If conversation has participants, extract other participant's name
        if (conversation['participants'] != null &&
            conversation['participants'] is List) {
          for (final participant in conversation['participants']) {
            if (participant is Map &&
                participant['id'] != null &&
                participant['id'].toString() != currentUserId.toString()) {
              // Use first and last name if available
              if (participant['first_name'] != null &&
                  participant['last_name'] != null) {
                final firstName = participant['first_name'] ?? '';
                final lastName = participant['last_name'] ?? '';
                contactName = '$firstName $lastName'.trim();
              } else {
                // Fall back to username
                contactName = participant['username'] ?? contactName;
              }
              break;
            }
          }
        }

        // Subscribe to notifications for this conversation
        if (firebaseId != null && firebaseId.isNotEmpty) {
          await _messageNotificationService.subscribeToConversation(
              firebaseId, contactName);
          debugPrint(
              'Subscribed to notifications for conversation: $conversationId ($contactName)');
        }
      }

      debugPrint(
          'Refreshed notifications for ${conversations.length} conversations');
    } catch (e) {
      debugPrint('Error refreshing conversation subscriptions: $e');
    }
  }

  // Handle app lifecycle changes (foreground, background, etc.)
  void handleAppLifecycleState(AppLifecycleState state) {
    // Update the app state in the message notification service
    _messageNotificationService.setAppState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in the foreground
        _refreshConversationSubscriptions();
        debugPrint('App resumed, refreshing notifications');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is going to background or being closed
        debugPrint('App going to background state: $state');
        break;
      case AppLifecycleState.hidden:
      // TODO: Handle this case.
    }
  }

  // Dispose resources
  void dispose() {
    _conversationRefreshTimer?.cancel();
    _messageNotificationService.unsubscribeAll();
    debugPrint('GlobalNotificationManager disposed');
  }
}
