import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';
import 'package:software_graduation_project/components/chat/message.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

class ChatPage extends StatefulWidget {
  final int chatId;
  const ChatPage({Key? key, required this.chatId}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  Future<Map<String, dynamic>?> _loadConversation() async {
    final jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/utils/chat_ex.json');
    List<dynamic> chats = json.decode(jsonString);
    var chatObj = chats.firstWhere(
      (chat) => chat['id'] == widget.chatId,
      orElse: () => null,
    );
    if (chatObj != null && !chatObj.containsKey('messages')) {
      chatObj['messages'] = []; // set empty conversation if none exists
    }
    return chatObj;
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    // For simplicity, here we just print the message and clear the field.
    // In real implementation, append to chat conversation & update the state accordingly.
    print("Send message: $content");
    _messageController.clear();
    setState(() {}); // refresh UI if needed
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final ts = DateTime.parse(msg['timestamp']);
    final formattedTime =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
    bool isSentByMe = msg['isSentByMe'] ?? false;
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment:
              isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSentByMe ? AppStyles.buttonColor : AppStyles.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSentByMe
                        ? AppStyles.lightPurple
                        : AppStyles.darkPurple,
                    width: 1),
              ),
              child: Text(
                msg['content'],
                style: TextStyle(
                  color: isSentByMe ? AppStyles.white : AppStyles.black,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      // appBar: AppBar(
      //   title: const Text('Chat'),
      //   backgroundColor: Colors.transparent,
      // ),
      body: Column(
        children: [
          // Expanded list of messages
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _loadConversation(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('No conversation found.'));
                }
                final chat = snapshot.data!;
                List<dynamic> messages = chat['messages'];
                // Sort messages from oldest to newest
                messages.sort((a, b) => DateTime.parse(a['timestamp'])
                    .compareTo(DateTime.parse(b['timestamp'])));

                if (messages.isEmpty) {
                  return const Center(child: Text('No messages available.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessage(messages[index]),
                );
              },
            ),
          ),
          // Input field for sending messages
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
