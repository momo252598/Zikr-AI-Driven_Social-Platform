import 'package:flutter/foundation.dart';
import 'package:software_graduation_project/services/chat_api_service.dart';
import 'package:software_graduation_project/services/unread_messages_service.dart';

/// Helper class for efficient badge count updates when marking messages as read
class BadgeRefresher {
  static final BadgeRefresher _instance = BadgeRefresher._internal();
  factory BadgeRefresher() => _instance;
  BadgeRefresher._internal();

  final UnreadMessagesService _unreadMessagesService = UnreadMessagesService();

  // This flag helps prevent too many rapid refreshes
  bool _isRefreshing = false;

  /// Refresh the badge count with debouncing to prevent too many updates
  Future<void> refreshBadgeCount() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      // Small delay to let Firebase/backend update read status first
      await Future.delayed(const Duration(milliseconds: 200));

      // Refresh the unread count
      await _unreadMessagesService.refreshUnreadCount();
      debugPrint('Badge refreshed via BadgeRefresher');
    } finally {
      // Reset refresh flag after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        _isRefreshing = false;
      });
    }
  }

  /// Force refresh without debouncing - use sparingly
  Future<void> forceRefreshBadgeCount() async {
    await _unreadMessagesService.refreshUnreadCount();
    debugPrint('Badge force-refreshed via BadgeRefresher');
  }

  /// Set the active conversation ID to ensure its messages aren't counted
  void setActiveConversation(String conversationId, {String? firebaseId}) {
    _unreadMessagesService.setActiveConversation(conversationId,
        firebaseId: firebaseId);
    forceRefreshBadgeCount();
    debugPrint('Set active conversation and refreshed badge count');
  }

  /// Clear the active conversation and refresh badge count
  void clearActiveConversation() {
    _unreadMessagesService.clearActiveConversation();
    forceRefreshBadgeCount();
    debugPrint('Cleared active conversation and refreshed badge count');
  }
}
