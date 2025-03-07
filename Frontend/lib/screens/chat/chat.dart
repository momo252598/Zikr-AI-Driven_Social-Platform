import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

class ChatPage extends StatefulWidget {
  final int chatId;
  const ChatPage({Key? key, required this.chatId}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  String contactName = ''; // Store the contact name
  Map<String, dynamic>? chatData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load conversation data when the page initializes
    _loadConversationData();
  }

  Future<void> _loadConversationData() async {
    try {
      final jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/utils/chat_ex.json');
      List<dynamic> chats = json.decode(jsonString);

      // Find our chat by ID
      Map<String, dynamic>? foundChat;
      for (var chat in chats) {
        if (chat['id'] == widget.chatId) {
          foundChat = Map<String, dynamic>.from(chat);
          break;
        }
      }

      if (foundChat != null) {
        // Ensure messages array exists
        if (!foundChat.containsKey('messages')) {
          foundChat['messages'] = [];
        }

        setState(() {
          chatData = foundChat;
          contactName = foundChat?['name'] ?? 'محادثة';
          isLoading = false;
        });
      } else {
        setState(() {
          contactName = 'محادثة غير موجودة';
          chatData = {'messages': []};
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading chat: $e');
      setState(() {
        contactName = 'خطأ';
        chatData = {'messages': []};
        isLoading = false;
      });
    }
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
      appBar: AppBar(
        title: Text(contactName,
            style: TextStyle(
              color: AppStyles.white,
            )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppStyles.darkPurple,
                AppStyles.lightPurple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: const DecorationImage(
              image: AssetImage(AppMedia.pattern3),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Color.fromARGB(96, 255, 255, 255),
                BlendMode.dstATop,
              ),
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppStyles.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Expanded list of messages
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessagesList(),
          ),
          // Input field for sending messages
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppStyles.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textAlign:
                        TextAlign.right, // added alignment for placeholder text
                    textDirection:
                        TextDirection.rtl, // set input direction to RTL
                    decoration: const InputDecoration(
                      hintText: '...اكتب رسالتك', // translated hint text
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

  Widget _buildMessagesList() {
    if (chatData == null) {
      return const Center(child: Text('لم يتم العثور على المحادثة'));
    }

    List<dynamic> messages = chatData!['messages'] ?? [];

    // Sort messages from oldest to newest
    if (messages.isNotEmpty) {
      messages.sort((a, b) => DateTime.parse(a['timestamp'])
          .compareTo(DateTime.parse(b['timestamp'])));
    }

    if (messages.isEmpty) {
      return const Center(child: Text('لا توجد رسائل بعد'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) => _buildMessage(messages[index]),
    );
  }
}
