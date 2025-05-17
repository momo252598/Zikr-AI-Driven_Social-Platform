import 'dart:async';
import 'package:flutter/material.dart';

class ChatNotificationHelper {
  // Singleton pattern
  static final ChatNotificationHelper _instance = ChatNotificationHelper._internal();
  factory ChatNotificationHelper() => _instance;
  ChatNotificationHelper._internal();

  // Track active conversation IDs (Firebase IDs or Django IDs)
  final Set<String> _activeConversationIds = <String>{};
  
  // Check if we are currently in a specific conversation
  bool isInConversation(String conversationId) {
    if (_activeConversationIds.isEmpty) return false;
    return _activeConversationIds.contains(conversationId);
  }

  // Register the current conversation
  void setActiveConversation(String? conversationId, {int? djangoId}) {
    // Clear previous active conversations
    _activeConversationIds.clear();
    
    // Add current conversation identifiers if valid
    if (conversationId != null && conversationId.isNotEmpty) {
      _activeConversationIds.add(conversationId);
    }
    
    if (djangoId != null) {
      _activeConversationIds.add(djangoId.toString());
    }
    
    debugPrint('Active conversation set: $_activeConversationIds');
  }

  // Clear active conversation when leaving chat
  void clearActiveConversation() {
    _activeConversationIds.clear();
    debugPrint('Active conversations cleared');
  }
  
  // Check if we should show a notification for this conversation
  bool shouldShowNotification(String conversationId) {
    bool inConversation = isInConversation(conversationId);
    debugPrint('Should show notification for $conversationId: ${!inConversation}');
    return !inConversation;
  }
}
