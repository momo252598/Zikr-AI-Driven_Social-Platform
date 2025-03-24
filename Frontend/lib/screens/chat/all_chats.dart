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

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // API call to get real conversations
      final conversations = await _chatApiService.getConversations();

      // Process the API response to ensure it has the expected format
      final processedChats = conversations.map((chat) {
        // Find the other participant's name for display
        String name = chat['name'] ?? '';
        if (name.isEmpty &&
            chat['participants'] != null &&
            chat['participants'] is List) {
          // For one-on-one chats, try to get the other user's name
          final participants = chat['participants'] as List;
          if (participants.isNotEmpty) {
            for (var participant in participants) {
              if (participant is Map && participant.containsKey('username')) {
                name = participant['username'];
                break;
              }
            }
          }
        }

        // Ensure the chat object has the required fields
        return {
          'id': chat['id'],
          'name': name.isNotEmpty ? name : 'محادثة',
          'firebase_id': chat['firebase_id'] ?? '',
          'last_message': chat['messages'] != null &&
                  chat['messages'] is List &&
                  (chat['messages'] as List).isNotEmpty
              ? (chat['messages'] as List).last
              : null,
          'timestamp': chat['updated_at'] ?? DateTime.now().toIso8601String(),
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
          _errorMessage = 'فشل في تحميل المحادثات. الرجاء المحاولة لاحقًا.';
        });
      }

      // Fallback to local data during development
      _loadLocalChats();
    }
  }

  Future<void> _loadLocalChats() async {
    try {
      final jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/utils/chat_ex.json');
      final loadedChats = json.decode(jsonString) as List<dynamic>;

      loadedChats.sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));

      if (mounted) {
        setState(() {
          _chats = List<Map<String, dynamic>>.from(loadedChats);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading local chats: $e');
      if (mounted) {
        setState(() {
          _chats = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => NewConversationDialog(
        onConversationCreated: (conversationId) {
          _loadChats(); // Reload chats after creating a new one
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: CustomAppBar(
        title: "جميع الرسائل",
        showAddButton: true,
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
                      const Text('لا توجد محادثات'),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _showNewConversationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.buttonColor,
                        ),
                        child: const Text('بدء محادثة جديدة'),
                      ),
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

                      // Extract the last message info
                      final lastMessage = chat['last_message'];
                      String messagePreview = 'لا توجد رسائل';

                      if (lastMessage != null) {
                        if (lastMessage is Map) {
                          if (lastMessage.containsKey('content_preview')) {
                            messagePreview = lastMessage['content_preview'] ??
                                messagePreview;
                          } else if (lastMessage.containsKey('content')) {
                            messagePreview =
                                lastMessage['content'] ?? messagePreview;
                          }
                        }
                      }

                      // Format the timestamp
                      DateTime timestamp;
                      if (lastMessage != null &&
                          lastMessage is Map &&
                          lastMessage.containsKey('timestamp')) {
                        // Handle different timestamp formats
                        final rawTimestamp = lastMessage['timestamp'];
                        if (rawTimestamp is int) {
                          timestamp =
                              DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
                        } else {
                          try {
                            timestamp = DateTime.parse(rawTimestamp.toString());
                          } catch (e) {
                            timestamp = DateTime.now();
                          }
                        }
                      } else {
                        try {
                          timestamp =
                              DateTime.parse(chat['timestamp'].toString());
                        } catch (e) {
                          timestamp = DateTime.now();
                        }
                      }

                      final formattedTime =
                          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

                      // Check if this chat is the selected one
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChatPage(chatId: chat['id']),
                                  ),
                                );
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
