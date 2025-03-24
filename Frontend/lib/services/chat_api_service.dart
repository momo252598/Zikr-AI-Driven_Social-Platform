import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/services/firebase_service.dart'; // Add this import

class ChatApiService {
  final String baseUrl = 'http://10.0.2.2:8000/api/chat';
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService =
      FirebaseService(); // Add Firebase service

  // Get user's conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final token = await _authService.getAccessToken();
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load conversations: $e');
    }
  }

  // Get single conversation details
  Future<Map<String, dynamic>> getConversationDetails(
      int conversationId) async {
    try {
      final token = await _authService.getAccessToken();
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$conversationId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load conversation details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load conversation details: $e');
    }
  }

  // Start a new conversation - update to also initialize Firebase conversation
  Future<Map<String, dynamic>> startConversation(
      String recipient, String initialMessage) async {
    try {
      final token = await _authService.getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/start/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode({'recipient': recipient, 'message': initialMessage}),
      );

      if (response.statusCode == 201) {
        final conversationData = json.decode(response.body);

        // Debug information
        print("Conversation data: $conversationData");

        // Now also initialize the Firebase conversation with the first message
        final user = await _authService.getCurrentUser();
        print("Current user: ${user?.toJson()}"); // Debug user data

        final conversationId = conversationData['id'];
        if (user != null && conversationId != null) {
          // Make sure user.id is not null
          if (user.id != null && user.username != null) {
            await _firebaseService.sendMessage(conversationId.toString(),
                initialMessage, user.id, user.username);
          } else {
            print(
                "Error: User ID or username is null. ID: ${user.id}, Username: ${user.username}");
          }
        } else {
          print(
              "Error: User or conversation ID is null. User: $user, Conversation ID: $conversationId");
        }

        return conversationData;
      } else {
        final errorBody = json.decode(response.body);
        print("Server error response: $errorBody");
        throw Exception('Failed to start conversation: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception in startConversation: $e");
      throw Exception('Failed to start conversation: $e');
    }
  }

  // Mark all messages in a conversation as read
  Future<void> markMessagesAsRead(int conversationId) async {
    try {
      final token = await _authService.getAccessToken();
      final response = await http.put(
        Uri.parse('$baseUrl/conversations/$conversationId/read/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to mark messages as read: ${response.statusCode}');
      }

      // Also mark messages as read in Firebase
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        // Get all messages for this conversation from Firebase and mark them as read
        final conversationIdStr = conversationId.toString();
        final messagesStream =
            _firebaseService.getMessagesStream(conversationIdStr);
        messagesStream.first.then((messages) {
          for (var message in messages) {
            _firebaseService.markMessageAsRead(
                conversationIdStr, message['id'], userId);
          }
        });
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Add a new message reference to Django
  Future<void> addMessageReference(
      int conversationId, String messageContent) async {
    try {
      final token = await _authService.getAccessToken();
      final user = await _authService.getCurrentUser();

      // First, send message to Firebase if user is not null
      if (user != null && user.id != null && user.username != null) {
        try {
          await _firebaseService.sendMessage(conversationId.toString(),
              messageContent, user.id, user.username);
        } catch (e) {
          print("Firebase error: $e");
          // Continue with the Django update even if Firebase fails
        }
      } else {
        print("Warning: Couldn't send to Firebase - missing user data");
      }

      // Then, update Django backend with message reference
      await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/messages/add/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode({
          'content_preview': messageContent.length > 100
              ? '${messageContent.substring(0, 97)}...'
              : messageContent
        }),
      );
    } catch (e) {
      print('Failed to add message: $e');
    }
  }
}
