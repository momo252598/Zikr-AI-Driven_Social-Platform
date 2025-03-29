import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';
import 'package:software_graduation_project/skeleton.dart';
import 'chat.dart';
import 'package:software_graduation_project/components/chat/skeleton_with_chat.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/services/chat_api_service.dart';
import 'package:software_graduation_project/services/firebase_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'new_conversation_dialog.dart';

class AllChatsPage extends StatefulWidget {
  final void Function(int)? onChatSelected;
  final int? selectedChatId;

  const AllChatsPage({Key? key, this.onChatSelected, this.selectedChatId})
      : super(key: key);

  @override
  _AllChatsPageState createState() => _AllChatsPageState();
}

class _AllChatsPageState extends State<AllChatsPage> {
  List<Map<String, dynamic>>? _chats;
  bool _isLoading = true;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  final ChatApiService _chatApiService = ChatApiService();
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndRefreshData();
  }

  Future<void> _checkAndRefreshData() async {
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _loadChats();
    }
  }

  // Replace the existing _ensureProperEncoding function with this improved version
  String _ensureProperEncoding(String text) {
    try {
      if (text.contains('Ø') || text.contains('Ù') || text.contains('Ú')) {
        // This specific pattern indicates incorrectly encoded Arabic text
        // We need to apply Latin-1 to UTF-8 conversion
        List<int> latinBytes = [];
        for (int i = 0; i < text.length; i++) {
          latinBytes.add(text.codeUnitAt(i) & 0xFF);
        }
        return utf8.decode(latinBytes);
      }
      return text; // Return original if no encoding issues detected
    } catch (e) {
      print('Error decoding text: $e');
      return text; // Return original if decoding fails
    }
  }

  Future<void> _loadChats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final conversations = await _chatApiService.getConversations();

      print("API Response: ${conversations.length} conversations");
      if (conversations.isNotEmpty) {
        print("First conversation sample: ${json.encode(conversations[0])}");
      }

      final currentUserId = await _authService.getCurrentUserId();

      final processedChats = conversations.map((chat) {
        String name = chat['name'] ?? '';

        if (chat['participants'] != null && chat['participants'] is List) {
          final participants = chat['participants'] as List;
          if (participants.isNotEmpty) {
            for (var participant in participants) {
              if (participant is Map &&
                  participant.containsKey('id') &&
                  participant['id'].toString() != currentUserId.toString()) {
                // Extract name from the participant data
                if (participant.containsKey('first_name') &&
                    participant.containsKey('last_name')) {
                  String firstName = participant['first_name'] ?? '';
                  String lastName = participant['last_name'] ?? '';

                  if (firstName.isNotEmpty || lastName.isNotEmpty) {
                    name = '$firstName $lastName'.trim();
                  } else {
                    name = participant['username'] ?? 'محادثة';
                  }
                } else {
                  name = participant['username'] ?? 'محادثة';
                }
                break;
              }
            }
          }
        }

        print("Chat ID ${chat['id']} - Messages: ${chat['messages']}");
        print("Chat ID ${chat['id']} - Last message: ${chat['last_message']}");

        String lastMessageText = 'لا توجد رسائل';
        String? timestamp =
            chat['updated_at'] ?? DateTime.now().toIso8601String();

        if (chat.containsKey('last_message') && chat['last_message'] != null) {
          if (chat['last_message'] is String) {
            lastMessageText = _ensureProperEncoding(chat['last_message']);
          } else if (chat['last_message'] is Map) {
            String contentText = chat['last_message']['content'] ??
                chat['last_message']['content_preview'] ??
                'لا توجد رسائل';
            lastMessageText = _ensureProperEncoding(contentText);
          }
        } else if (chat.containsKey('last_message_content') &&
            chat['last_message_content'] != null) {
          lastMessageText = _ensureProperEncoding(chat['last_message_content']);
        } else if (chat['messages'] != null &&
            chat['messages'] is List &&
            (chat['messages'] as List).isNotEmpty) {
          final messages = chat['messages'] as List;
          final lastMsg = messages.last;
          if (lastMsg is Map) {
            String contentText = 'لا توجد رسائل';
            if (lastMsg.containsKey('content_preview')) {
              contentText = lastMsg['content_preview'] ?? contentText;
            } else if (lastMsg.containsKey('content')) {
              contentText = lastMsg['content'] ?? contentText;
            }
            lastMessageText = _ensureProperEncoding(contentText);

            if (lastMsg.containsKey('created_at') &&
                lastMsg['created_at'] != null) {
              timestamp = lastMsg['created_at'];
            } else if (lastMsg.containsKey('timestamp') &&
                lastMsg['timestamp'] != null) {
              timestamp = lastMsg['timestamp'].toString();
            }
          }
        }

        return {
          'id': chat['id'],
          'name': name.isNotEmpty ? name : 'محادثة',
          'firebase_id': chat['firebase_id'] ?? '',
          'last_message_text': lastMessageText,
          'timestamp': timestamp,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _chats = processedChats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading chats: $e');
      if (mounted) {
        setState(() {
          _chats = [];
          _isLoading = false;
          // _errorMessage = 'فشل في تحميل المحادثات. الرجاء المحاولة لاحقًا.';
        });
      }
    }
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => NewConversationDialog(
        onConversationCreated: (conversationId) {
          _loadChats();

          if (widget.onChatSelected != null) {
            widget.onChatSelected!(conversationId);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(chatId: conversationId),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _navigateToChat(int chatId) async {
    if (widget.onChatSelected != null) {
      widget.onChatSelected!(chatId);
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(chatId: chatId),
        ),
      );

      if (result == true) {
        _loadChats();
      }
    }
  }

  Future<void> updateSpecificChat(int chatId, String lastMessage) async {
    if (_chats == null) return;

    // Find the chat in the list
    final chatIndex = _chats!.indexWhere((chat) => chat['id'] == chatId);
    if (chatIndex == -1) return;

    // Update just the last message for this chat
    setState(() {
      _chats![chatIndex]['last_message_text'] =
          _ensureProperEncoding(lastMessage);
      _chats![chatIndex]['timestamp'] = DateTime.now().toIso8601String();

      // Move this chat to the top of the list
      if (chatIndex > 0) {
        final updatedChat = _chats![chatIndex];
        _chats!.removeAt(chatIndex);
        _chats!.insert(0, updatedChat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: CustomAppBar(
        title: "جميع الرسائل",
        showAddButton:
            false, // Changed from true to false to remove the + button
        showBackButton: true,
        onAddPressed: _showNewConversationDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_chats == null || _chats!.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 80,
                        color: AppStyles.lightPurple,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'لا توجد محادثات بعد',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ابدأ محادثة جديدة للتواصل مع الآخرين',
                        textAlign: TextAlign.center,
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      // Removed the ElevatedButton that was here
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _chats!.length,
                    itemBuilder: (context, index) {
                      final chat = _chats![index];

                      String messagePreview =
                          chat['last_message_text'] ?? 'لا توجد رسائل';

                      print(
                          'Chat ${chat['id']} - Displaying message preview: $messagePreview');

                      DateTime timestamp;
                      try {
                        final rawTimestamp = chat['timestamp'];
                        if (rawTimestamp is int) {
                          timestamp =
                              DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
                        } else {
                          timestamp = DateTime.parse(rawTimestamp.toString());
                        }
                      } catch (e) {
                        timestamp = DateTime.now();
                      }

                      final formattedTime =
                          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

                      final isSelected = widget.selectedChatId == chat['id'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppStyles.darkPurple
                                  : AppStyles.lightPurple,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          color: isSelected ? AppStyles.whitePurple : null,
                          elevation: isSelected ? 5 : 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            title: Text(
                              chat['name'] ?? 'محادثة',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                            ),
                            subtitle: Text(
                              messagePreview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              formattedTime,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () {
                              if (widget.onChatSelected != null) {
                                widget.onChatSelected!(chat['id']);
                              } else {
                                _navigateToChat(chat['id']);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewConversationDialog,
        backgroundColor: AppStyles.buttonColor,
        child: const Icon(Icons.message),
      ),
    );
  }
}
