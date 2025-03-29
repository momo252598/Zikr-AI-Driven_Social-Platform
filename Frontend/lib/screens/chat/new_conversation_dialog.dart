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
  final ChatApiService _chatApiService = ChatApiService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _startConversation() async {
    final recipient = _recipientController.text.trim();

    if (recipient.isEmpty) {
      setState(() {
        _errorMessage =
            'الرجاء إدخال اسم المستخدم أو البريد الإلكتروني للمستلم';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Start conversation in Django with empty message
      final result = await _chatApiService.startConversation(recipient, '');

      // Debug log the actual response
      print('Server response: $result');

      // Validate the server response properly
      if (result == null) {
        throw Exception('لم يتم استلام رد من الخادم');
      }

      // Extract the conversation ID, handling nested structure
      int? conversationId;

      // Check if the response has a nested 'conversation' object
      if (result.containsKey('conversation') && result['conversation'] is Map) {
        final conversation = result['conversation'] as Map;

        // Extract ID from the conversation object
        if (conversation.containsKey('id')) {
          conversationId = conversation['id'] is int
              ? conversation['id']
              : int.tryParse(conversation['id'].toString());
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
      }

      // If we still couldn't find a valid conversation ID
      if (conversationId == null) {
        throw Exception(
            'رد غير صالح من الخادم: لا يوجد معرف للمحادثة.\nمحتوى الرد: ${result.toString()}');
      }

      // First close the dialog to prevent context issues
      Navigator.of(context).pop();

      // Then notify the parent widget to handle navigation
      // This is done after pop() to avoid context issues
      widget.onConversationCreated(conversationId);
    } catch (e) {
      print('Error in startConversation: $e');
      if (mounted) {
        setState(() {
          String errorString = e.toString().toLowerCase();

          // Check for self-messaging error specifically
          if (errorString
                  .contains('cannot start a conversation with yourself') ||
              errorString.contains('conversation with yourself')) {
            _errorMessage = 'لا يمكنك بدء محادثة مع نفسك';
          }
          // Handle 400 status code with missing user error message
          else if (errorString.contains('400') &&
              errorString.contains('user not found')) {
            _errorMessage = 'المستخدم غير موجود';
          }
          // Handle generic 400 self-message error (could be just the status code)
          else if (errorString.contains('400')) {
            _errorMessage = 'لا يمكنك بدء محادثة مع نفسك';
          } else {
            // Clean up the error message
            String errorMsg = errorString;
            errorMsg = errorMsg.replaceAll('exception:', '').trim();
            // Remove HTTP status codes
            errorMsg = errorMsg.replaceAll(RegExp(r'[0-9]{3}'), '').trim();
            // Remove common JSON formatting
            errorMsg = errorMsg.replaceAll(RegExp(r'[\{\}"\\]'), '').trim();
            errorMsg = errorMsg.replaceAll('error:', '').trim();

            if (errorMsg.isEmpty) {
              _errorMessage = 'فشل في بدء المحادثة';
            } else {
              _errorMessage = 'فشل في بدء المحادثة: $errorMsg';
            }
          }
        });
      }
    } finally {
      // Always reset loading state even if there was an error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              : const Text('بدء المحادثة'),
        ),
      ],
    );
  }
}
