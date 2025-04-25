import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb; // Add kIsWeb import
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/services/firebase_service.dart';
import 'package:software_graduation_project/utils/text_utils.dart'; // Import utility

class ChatApiService {
  late final String baseUrl; // Change to late final
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  ChatApiService() {
    // Use 127.0.0.1 when running on web, otherwise use 192.168.1.19 (for Android emulator)
    final host = kIsWeb ? '127.0.0.1' : '192.168.1.19';
    baseUrl = 'http://$host:8000/api/chat';
  }

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
        print(
            "Raw API response: ${response.body.substring(0, 200)}..."); // Print first 200 chars

        // Debug the structure to see what fields are available
        if (data is List && data.isNotEmpty) {
          print(
              "First conversation structure keys: ${(data[0] as Map).keys.toList()}");

          // Check specifically for last message fields
          final firstChat = data[0] as Map;
          if (firstChat.containsKey('messages')) {
            print("Messages field exists. Sample: ${firstChat['messages']}");
          }
          if (firstChat.containsKey('last_message')) {
            print(
                "last_message field exists. Value: ${firstChat['last_message']}");
          }
        }

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

  // Start a new conversation - update to make initialMessage optional
  Future<Map<String, dynamic>> startConversation(
      String recipient, String initialMessage) async {
    try {
      final token = await _authService.getAccessToken();

      // Fix any encoding issues with the message before sending
      final String processedMessage =
          TextUtils.prepareForSending(initialMessage);

      // Prepare the request body - only include message if not empty
      final Map<String, dynamic> requestBody = {'recipient': recipient};
      if (processedMessage.isNotEmpty) {
        requestBody['message'] = processedMessage;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/conversations/start/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print("Full API Response: $responseData");

        // Extract the conversation data from the nested structure
        final conversationData = responseData['conversation'] ?? responseData;
        print("Extracted conversation data: $conversationData");

        // Get the current user for Firebase interactions
        final user = await _authService.getCurrentUser();
        print("Current user: ${user?.toJson()}");

        // Extract conversation ID and firebase_id properly
        final conversationId = conversationData['id'];
        final firebaseId = conversationData['firebase_id'];

        print(
            "Extracted IDs - conversation ID: $conversationId, Firebase ID: $firebaseId");

        // Only send Firebase message if there is an initial message
        if (processedMessage.isNotEmpty &&
            user != null &&
            firebaseId != null &&
            user.id != null &&
            user.username != null) {
          // Check if the server indicates the message was already sent to Firebase
          final messageSentToFirebase =
              responseData['message_sent_to_firebase'] ?? false;

          if (!messageSentToFirebase) {
            print(
                "Sending initial message to Firebase with conversation ID: $firebaseId");
            try {
              await _firebaseService.sendMessage(firebaseId.toString(),
                  processedMessage, user.id, user.username);
              print("Initial message sent to Firebase successfully");
            } catch (e) {
              print("Error sending initial message to Firebase: $e");
              // Continue even if Firebase fails - don't rethrow
            }
          } else {
            print("Message was already sent to Firebase by server");
          }
        } else {
          print("No initial message to send to Firebase or missing data");
        }

        // Return the full response data for maximum compatibility
        return responseData;
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

      // Fix any encoding issues with the message
      final processedContent = TextUtils.prepareForSending(messageContent);

      // Only update Django backend with message reference
      await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/messages/add/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode({
          'content': processedContent, // Send properly encoded content
          'content_preview': processedContent.length > 100
              ? '${processedContent.substring(0, 97)}...'
              : processedContent
        }),
      );
    } catch (e) {
      print('Failed to add message: $e');
    }
  }
}
