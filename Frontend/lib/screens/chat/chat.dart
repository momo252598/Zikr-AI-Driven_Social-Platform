import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/services/chat_api_service.dart';
import 'package:software_graduation_project/services/firebase_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';

class ChatPage extends StatefulWidget {
  final int chatId;
  const ChatPage({Key? key, required this.chatId}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatApiService _chatApiService = ChatApiService();
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  String contactName = '';
  Map<String, dynamic>? chatData;
  bool isLoading = true;
  List<Map<String, dynamic>> messages = [];
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;
  Map<int, int> typingUsers = {};
  int? currentUserId;
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Get current user ID
    currentUserId = await _authService.getCurrentUserId();

    // Load conversation data
    await _loadConversationData();

    // Mark messages as read
    _chatApiService.markMessagesAsRead(widget.chatId);

    // Subscribe to messages
    final conversationFirebaseId = chatData?['firebase_id'];
    if (conversationFirebaseId != null) {
      _subscribeToMessages(conversationFirebaseId);
      _subscribeToTypingIndicators(conversationFirebaseId);
    }

    // Set user as online
    if (currentUserId != null) {
      _firebaseService.updateUserPresence(currentUserId!, true);
    }
  }

  @override
  void didUpdateWidget(ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      // Clean up old subscriptions
      _messagesSubscription?.cancel();
      _typingSubscription?.cancel();

      setState(() {
        isLoading = true;
        messages = [];
      });

      _initialize();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversationData() async {
    try {
      // First try loading from the API
      final conversation =
          await _chatApiService.getConversationDetails(widget.chatId);

      setState(() {
        chatData = conversation;
        contactName = conversation['name'] ?? 'محادثة';
        isLoading = false;
      });
    } catch (e) {
      print('Error loading chat from API: $e');

      // Fallback to local data during development
      _loadLocalConversationData();
    }
  }

  Future<void> _loadLocalConversationData() async {
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
      print('Error loading local chat data: $e');
      setState(() {
        contactName = 'خطأ';
        chatData = {'messages': []};
        isLoading = false;
      });
    }
  }

  void _subscribeToMessages(String firebaseId) {
    _messagesSubscription =
        _firebaseService.getMessagesStream(firebaseId).listen((newMessages) {
      if (mounted) {
        setState(() {
          messages = newMessages;

          // Mark messages as read
          if (currentUserId != null) {
            for (var message in newMessages) {
              // Ensure consistent type comparison
              String msgSenderId = message['sender_id'].toString();
              String curUserId = currentUserId.toString();

              if (msgSenderId != curUserId) {
                _firebaseService.markMessageAsRead(
                    firebaseId, message['id'], currentUserId!);
              }
            }
          }
        });
      }
    });
  }

  void _subscribeToTypingIndicators(String firebaseId) {
    _typingSubscription = _firebaseService
        .getTypingIndicatorsStream(firebaseId)
        .listen((typingData) {
      if (mounted) {
        setState(() {
          typingUsers = typingData;
        });
      }
    });
  }

  void _handleTyping(bool isTyping) {
    _typingTimer?.cancel();

    if (isTyping && !_isTyping) {
      _setTypingStatus(true);
    }

    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _setTypingStatus(false);
      });
    }
  }

  void _setTypingStatus(bool isTyping) {
    if (currentUserId != null && chatData != null) {
      _isTyping = isTyping;
      _firebaseService.setTypingStatus(
          chatData!['firebase_id'], currentUserId!, isTyping);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || chatData == null || currentUserId == null) return;

    _messageController.clear();
    _setTypingStatus(false);

    try {
      // Send message to Firebase
      await _firebaseService.sendMessage(chatData!['firebase_id'], content,
          currentUserId!, await _authService.getCurrentUsername() ?? 'User');

      // Create message reference in Django
      await _chatApiService.addMessageReference(widget.chatId, content);
    } catch (e) {
      print("Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إرسال الرسالة: $e')),
      );
    }
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] as int);
    final formattedTime =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    // Fix comparison by ensuring both values are strings
    bool isSentByMe = false;
    if (currentUserId != null) {
      // Get the sender ID from the message
      final senderId = msg['sender_id'];
      // Convert both to strings for reliable comparison
      final senderIdString = senderId.toString();
      final currentUserIdString = currentUserId.toString();

      // Log the values for debugging
      print('Message: sender_id=$senderId (${senderId.runtimeType}), '
          'currentUserId=$currentUserId (${currentUserId.runtimeType})');
      print(
          'After toString: sender_id=$senderIdString, currentUserId=$currentUserIdString, '
          'equal=${senderIdString == currentUserIdString}');

      isSentByMe = senderIdString == currentUserIdString;
    }

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

  Widget _buildTypingIndicator() {
    // Filter out current user and expired typing indicators
    final typingUserIds =
        typingUsers.keys.where((userId) => userId != currentUserId).toList();

    if (typingUserIds.isEmpty) return const SizedBox();

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppStyles.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('جاري الكتابة'),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Row(
                  children: [
                    _buildDot(0),
                    _buildDot(1),
                    _buildDot(2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Expanded(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: 6,
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppStyles.darkPurple.withOpacity(0.5 + (index * 0.2)),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: CustomAppBar(
          title: contactName, showAddButton: false, showBackButton: !kIsWeb),
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
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      hintText: '...اكتب رسالتك',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      // Notify typing status
                      _handleTyping(text.isNotEmpty);
                    },
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
    if (messages.isEmpty) {
      return const Center(child: Text('لا توجد رسائل بعد'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: messages.length + 1, // +1 for typing indicator
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessage(messages[index]);
      },
    );
  }
}
