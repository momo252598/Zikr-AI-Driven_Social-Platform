import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_graduation_project/services/chat_api_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';

class UnreadMessagesService {
  // Singleton pattern
  static final UnreadMessagesService _instance =
      UnreadMessagesService._internal();
  factory UnreadMessagesService() => _instance;
  UnreadMessagesService._internal();
  // Services
  final ChatApiService _chatApiService = ChatApiService();
  final AuthService _authService = AuthService();

  // Stream controllers
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  // State variables
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  bool _isInitialized = false;
  Timer? _refreshTimer;

  // Track active conversations (where user is currently viewing)
  final Set<String> _activeConversationIds = {}; // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check if user is authenticated
    final currentUserId = await _authService.getCurrentUserId();
    if (currentUserId == null) {
      debugPrint(
          'User not authenticated, unread message service initialization delayed');
      return;
    }

    _isInitialized = true;

    // Fetch initial unread messages count
    await refreshUnreadCount();

    // Set up more frequent periodic refresh (every 15 seconds instead of every minute)
    // This will make the badge count update more responsive
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      refreshUnreadCount();
    });

    debugPrint(
        'UnreadMessagesService initialized with 15-second refresh interval');
  }

  // Dispose resources
  void dispose() {
    _refreshTimer?.cancel();
    // Don't close the stream controller as it's a singleton
  } // Refresh the unread messages count - optimized for faster updates

  Future<void> refreshUnreadCount() async {
    try {
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) return;

      // Store the previous count for comparison
      final previousUnreadCount = _unreadCount;

      // Fetch all conversations with a more explicit "no cache" approach
      final conversations = await _chatApiService.getConversations();

      int unreadCount = 0;

      // Count unread messages across all conversations
      for (final conversation in conversations) {
        // Skip active conversations
        final conversationId = conversation['id'].toString();
        final firebaseId = conversation['firebase_id']?.toString();

        if (_isConversationActive(conversationId, firebaseId)) {
          continue;
        }

        // Use the unread_count field provided by the backend
        if (conversation.containsKey('unread_count')) {
          final conversationUnreadCount =
              conversation['unread_count'] as int? ?? 0;
          unreadCount += conversationUnreadCount;

          if (conversationUnreadCount > 0) {
            debugPrint(
                'Found $conversationUnreadCount unread messages in conversation $conversationId');
          }
        }
        // Fallback to checking last message for older API versions
        else {
          final lastMessage = conversation['last_message'];
          if (lastMessage != null && lastMessage is Map) {
            // Check if the message has sender_id and is_read fields
            final senderId = lastMessage['sender_id']?.toString() ??
                lastMessage['sender']?.toString();
            final isRead = lastMessage['is_read'] == true;

            if (!isRead &&
                senderId != null &&
                senderId != currentUserId.toString()) {
              unreadCount++;
              debugPrint(
                  'Found unread message in conversation $conversationId using fallback method');
            }
          }
        }
      }

      // Always update the count, even if it hasn't changed
      // This ensures the UI refreshes properly
      _unreadCount = unreadCount;
      _unreadCountController.add(_unreadCount);

      // Store the count in shared prefs for persistence across restarts
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_messages_count', _unreadCount);

      if (previousUnreadCount != _unreadCount) {
        debugPrint(
            'Badge count changed from $previousUnreadCount to $_unreadCount');
      } else {
        debugPrint('Badge count remains at $_unreadCount');
      }
    } catch (e) {
      debugPrint('Error refreshing unread messages: $e');
    }
  }

  // Mark a conversation as active (user is viewing it)
  void setActiveConversation(String conversationId, {String? firebaseId}) {
    _activeConversationIds.clear(); // Only one active at a time

    if (conversationId.isNotEmpty) {
      _activeConversationIds.add(conversationId);
    }

    if (firebaseId != null && firebaseId.isNotEmpty) {
      _activeConversationIds.add(firebaseId);
    }

    refreshUnreadCount(); // Refresh to exclude this conversation
  }

  // Clear active conversation
  void clearActiveConversation() {
    _activeConversationIds.clear();
    refreshUnreadCount(); // Refresh to include all conversations
  }

  // Check if conversation is active
  bool _isConversationActive(String? conversationId, String? firebaseId) {
    if (_activeConversationIds.isEmpty) return false;

    if (conversationId != null &&
        _activeConversationIds.contains(conversationId)) {
      return true;
    }

    if (firebaseId != null && _activeConversationIds.contains(firebaseId)) {
      return true;
    }

    return false;
  }

  // Force reset unread count (e.g. after the user views all chats)
  Future<void> resetUnreadCount() async {
    _unreadCount = 0;
    _unreadCountController.add(_unreadCount);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_messages_count', 0);

    debugPrint('Reset unread messages count to 0');
  }

  // Load persisted unread count on app start
  Future<void> loadPersistedUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final persistedCount = prefs.getInt('unread_messages_count') ?? 0;

      if (persistedCount > 0) {
        _unreadCount = persistedCount;
        _unreadCountController.add(_unreadCount);
        debugPrint('Loaded persisted unread count: $_unreadCount');
      }
    } catch (e) {
      debugPrint('Error loading persisted unread count: $e');
    }
  }
}
