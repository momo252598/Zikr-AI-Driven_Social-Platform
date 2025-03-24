import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/services/chat_api_service.dart';
import 'package:software_graduation_project/services/firebase_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';

class NewConversationDialog extends StatefulWidget {
  final Function(int) onConversationCreated;

  const NewConversationDialog({Key? key, required this.onConversationCreated})
      : super(key: key);

  @override
  _NewConversationDialogState createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<NewConversationDialog> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ChatApiService _chatApiService = ChatApiService();
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _startConversation() async {
    final recipient = _recipientController.text.trim();
    final message = _messageController.text.trim();

    if (recipient.isEmpty) {
      setState(() {
        _errorMessage =
            'الرجاء إدخال اسم المستخدم أو البريد الإلكتروني للمستلم';
      });
      return;
    }

    if (message.isEmpty) {
      setState(() {
        _errorMessage = 'الرجاء إدخال رسالة';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Start conversation in Django and get the conversation details first
      final result =
          await _chatApiService.startConversation(recipient, message);

      // Debug log the actual response
      print('Server response: $result');

      // Validate the server response properly
      if (result == null) {
        throw Exception('لم يتم استلام رد من الخادم');
      }

      // For debugging purposes, log the keys in the response
      print('Response keys: ${result.keys.toList()}');

      // Extract the conversation ID, handling nested structure
      int? conversationId;
      String? firebaseId;

      // Check if the response has a nested 'conversation' object
      if (result.containsKey('conversation') && result['conversation'] is Map) {
        final conversation = result['conversation'] as Map;

        // Extract ID from the conversation object
        if (conversation.containsKey('id')) {
          conversationId = conversation['id'] is int
              ? conversation['id']
              : int.tryParse(conversation['id'].toString());
        }

        // Extract Firebase ID from the conversation object
        if (conversation.containsKey('firebase_id')) {
          firebaseId = conversation['firebase_id'].toString();
        }
      } else {
        // Fall back to looking for ID at top level
        if (result.containsKey('id') && result['id'] != null) {
          conversationId = result['id'] is int
              ? result['id']
              : int.tryParse(result['id'].toString());
        } else if (result.containsKey('conversation_id') &&
            result['conversation_id'] != null) {
          conversationId = result['conversation_id'] is int
              ? result['conversation_id']
              : int.tryParse(result['conversation_id'].toString());
        }

        // Look for Firebase ID at top level
        if (result.containsKey('firebase_id') &&
            result['firebase_id'] != null) {
          firebaseId = result['firebase_id'].toString();
        }
      }

      // If we still couldn't find a valid conversation ID
      if (conversationId == null) {
        throw Exception(
            'رد غير صالح من الخادم: لا يوجد معرف للمحادثة.\nمحتوى الرد: ${result.toString()}');
      }

      // Get the current user info
      final currentUserId = await _authService.getCurrentUserId();
      final currentUsername = await _authService.getCurrentUsername() ?? 'User';

      // Only attempt Firebase operations if we have the necessary data
      if (firebaseId != null &&
          firebaseId.isNotEmpty &&
          currentUserId != null) {
        try {
          // Ensure Firebase authentication before sending message
          await _firebaseService.signInWithCustomToken();

          // Send the first message to Firebase
          await _firebaseService.sendMessage(
              firebaseId, message, currentUserId, currentUsername);
        } catch (firebaseError) {
          // Log Firebase error but continue with Django conversation
          print('Firebase error: $firebaseError');
          // Don't rethrow - we'll still consider the conversation created
        }
      }

      // Everything went well, notify the parent widget and close the dialog
      widget.onConversationCreated(conversationId);
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        // Clean up the error message to make it more user-friendly
        String errorMsg = e.toString();
        errorMsg = errorMsg.replaceAll('Exception: ', '');
        _errorMessage = 'فشل في بدء المحادثة: $errorMsg';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('محادثة جديدة', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم أو البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'رسالتك',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              minLines: 3,
              maxLines: 5,
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _startConversation,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.buttonColor,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إرسال'),
        ),
      ],
    );
  }
}
