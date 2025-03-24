import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart'; // Your Django auth service

class FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService(); // Your Django auth service

  // Sign in with custom token from Django
  Future<void> signInWithCustomToken() async {
    try {
      print("Attempting to get Firebase token from Django...");
      // Get the token from Django backend
      final token = await _authService.getFirebaseToken();

      if (token != null) {
        print(
            "Received token: ${token.substring(0, 20)}..."); // Show first part of token for debugging
        try {
          // Sign in to Firebase with the custom token
          final userCredential = await _auth.signInWithCustomToken(token);
          print(
              "Firebase auth successful, user ID: ${userCredential.user?.uid}");
        } catch (authError) {
          print("Firebase auth specific error: $authError");

          // Try anonymous authentication as a fallback
          print("Trying anonymous authentication as fallback...");
          await _auth.signInAnonymously();
          print("Anonymous auth successful, ID: ${_auth.currentUser?.uid}");
        }
      } else {
        print("Failed to get Firebase token from Django");

        // Try anonymous authentication as a fallback
        print("Trying anonymous authentication as fallback...");
        await _auth.signInAnonymously();
        print("Anonymous auth successful, ID: ${_auth.currentUser?.uid}");
      }
    } catch (e) {
      print('Firebase signin error: $e');

      // Last resort fallback - try anonymous auth even after general errors
      try {
        print("Trying anonymous authentication after error...");
        await _auth.signInAnonymously();
        print(
            "Anonymous auth successful after error, ID: ${_auth.currentUser?.uid}");
      } catch (anonError) {
        print("Even anonymous auth failed: $anonError");
        throw Exception('Could not authenticate with Firebase: $e');
      }
    }
  }

  // Create a new conversation or get existing one
  Future<String> createOrGetConversation(int otherUserId) async {
    if (_auth.currentUser == null) {
      await signInWithCustomToken();
    }

    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null)
      throw Exception('Not authenticated with Firebase');

    // Create a unique chat ID by sorting participant IDs
    final participantIds = [int.parse(currentUserId), otherUserId]..sort();
    final conversationId = 'chat_${participantIds[0]}_${participantIds[1]}';

    // Check if conversation exists
    final snapshot = await _database.ref('messages/$conversationId').get();
    if (!snapshot.exists) {
      // Initialize conversation
      await _database.ref('messages/$conversationId/participants').set({
        currentUserId: true,
        otherUserId.toString(): true,
      });

      // Set metadata
      await _database.ref('conversations/$conversationId').set({
        'participants': [int.parse(currentUserId), otherUserId],
        'created_at': ServerValue.timestamp,
        'last_activity': ServerValue.timestamp,
      });

      print("New conversation created: $conversationId");
    }

    return conversationId;
  }

  // Get all conversations for the current user
  Stream<List<Map<String, dynamic>>> getUserConversations() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null)
      throw Exception('Not authenticated with Firebase');

    return _database
        .ref('conversations')
        .orderByChild('last_activity')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      List<Map<String, dynamic>> conversations = [];
      data.forEach((key, value) {
        final conversationData = Map<String, dynamic>.from(value as Map);
        if ((conversationData['participants'] as List)
            .contains(int.parse(currentUserId))) {
          conversationData['id'] = key;
          conversations.add(conversationData);
        }
      });

      // Sort by last activity (newest first)
      conversations.sort((a, b) =>
          (b['last_activity'] as int).compareTo(a['last_activity'] as int));
      return conversations;
    });
  }

  // Listen to messages in a conversation
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    return _database.ref('messages/$conversationId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      List<Map<String, dynamic>> messages = [];
      data.forEach((key, value) {
        if (key != 'participants' && key != 'typing') {
          final message = Map<String, dynamic>.from(value as Map);
          message['id'] = key;
          messages.add(message);
        }
      });

      // Sort by timestamp
      messages.sort(
          (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
      return messages;
    });
  }

  // Send a new message
  Future<void> sendMessage(String conversationId, String content, int senderId,
      String senderUsername) async {
    try {
      // Validate inputs before proceeding
      if (conversationId.isEmpty) {
        print("Error: Empty conversation ID");
        return;
      }

      if (senderId == null) {
        print("Error: Sender ID is null");
        return;
      }

      final ref = _database.ref('messages/$conversationId').push();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Convert senderId to string to ensure consistent type handling in Firebase
      final senderIdString = senderId.toString();

      // Log the exact data we're sending for debugging
      print(
          "Sending message with senderId: $senderId (as string: $senderIdString)");

      await ref.set({
        'content': content,
        'timestamp': timestamp,
        'sender_id': senderIdString, // Store as string consistently
        'sender_username': senderUsername,
        'read_by': {senderIdString: true}
      });

      // Update last activity for the conversation
      await _database.ref('conversations/$conversationId').update({
        'last_activity': timestamp,
        'last_message': content,
        'last_sender_id': senderIdString // Use string here too for consistency
      });

      print("Message successfully sent to Firebase");
    } catch (e) {
      print("Firebase sendMessage error: $e");
      // Re-throw the error to be handled by the caller
      throw e;
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(
      String conversationId, String messageId, int userId) async {
    await _database
        .ref('messages/$conversationId/$messageId/read_by/$userId')
        .set(true);
  }

  // Set typing indicator
  Future<void> setTypingStatus(
      String conversationId, int userId, bool isTyping) async {
    if (isTyping) {
      await _database
          .ref('typing/$conversationId/$userId')
          .set(DateTime.now().millisecondsSinceEpoch);
    } else {
      await _database.ref('typing/$conversationId/$userId').remove();
    }
  }

  // Listen to typing indicators
  Stream<Map<int, int>> getTypingIndicatorsStream(String conversationId) {
    return _database.ref('typing/$conversationId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};

      final Map<int, int> typingUsers = {};
      data.forEach((key, value) {
        typingUsers[int.parse(key.toString())] = value as int;
      });

      return typingUsers;
    });
  }

  // Update user presence
  Future<void> updateUserPresence(int userId, bool isOnline) async {
    final userPresenceRef = _database.ref('presence/$userId');
    await userPresenceRef.set({
      'online': isOnline,
      'last_seen': DateTime.now().millisecondsSinceEpoch
    });

    // Set up onDisconnect to update status when user goes offline
    if (isOnline) {
      userPresenceRef
          .onDisconnect()
          .update({'online': false, 'last_seen': ServerValue.timestamp});
    }
  }

  // Get user's presence stream
  Stream<Map<String, dynamic>> getUserPresence(int userId) {
    return _database.ref('presence/$userId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return {'online': false, 'last_seen': null};
      }
      return Map<String, dynamic>.from(data);
    });
  }
}
