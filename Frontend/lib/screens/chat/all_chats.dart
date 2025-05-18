import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';
import 'package:software_graduation_project/skeleton.dart';
import 'package:software_graduation_project/utils/text_utils.dart'; // Import utility
import 'package:software_graduation_project/utils/verification_badge.dart'; // Import for sheikh badges
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

class _AllChatsPageState extends State<AllChatsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>>? _chats;
  bool _isLoading = true;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  final ChatApiService _chatApiService = ChatApiService();
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  int? _currentUserId; // Store current user ID for badge checks
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadChats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    final fixed = TextUtils.fixArabicEncoding(text);
    // Log for debugging
    print('Original text: "$text"');
    print('Fixed text: "$fixed"');
    return fixed;
  }

  Future<void> _loadChats() async {
    try {
      print('======= LOADING CHATS - ARABIC TEXT DEBUGGING =======');
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final conversations = await _chatApiService.getConversations();

      print("API Response: ${conversations.length} conversations");
      if (conversations.isNotEmpty) {
        print("First conversation sample: ${json.encode(conversations[0])}");
      }

      // Get current user ID to identify which participants are not the current user
      _currentUserId = await _authService.getCurrentUserId();

      final processedChats = conversations.map((chat) {
        String name = TextUtils.fixArabicEncoding(chat['name'] ?? '');
        bool isSheikh =
            false; // Add flag to track if the other participant is a sheikh

        if (chat['participants'] != null && chat['participants'] is List) {
          final participants = chat['participants'] as List;
          if (participants.isNotEmpty) {
            for (var participant in participants) {
              if (participant is Map &&
                  participant.containsKey('id') &&
                  participant['id'].toString() != _currentUserId.toString()) {
                // Check if other participant is a sheikh
                if (participant.containsKey('user_type')) {
                  isSheikh = participant['user_type'] == 'sheikh';
                }

                // Extract name from the participant data
                if (participant.containsKey('first_name') &&
                    participant.containsKey('last_name')) {
                  String firstName = participant['first_name'] ?? '';
                  String lastName = participant['last_name'] ?? '';

                  if (firstName.isNotEmpty || lastName.isNotEmpty) {
                    name = TextUtils.fixArabicEncoding(
                        '$firstName $lastName'.trim());
                  } else {
                    name = TextUtils.fixArabicEncoding(
                        participant['username'] ?? 'محادثة');
                  }
                } else {
                  name = TextUtils.fixArabicEncoding(
                      participant['username'] ?? 'محادثة');
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
            lastMessageText = TextUtils.fixArabicEncoding(chat['last_message']);
          } else if (chat['last_message'] is Map) {
            String contentText = chat['last_message']['content'] ??
                chat['last_message']['content_preview'] ??
                'لا توجد رسائل';
            lastMessageText = TextUtils.fixArabicEncoding(contentText);
          }
        } else if (chat.containsKey('last_message_content') &&
            chat['last_message_content'] != null) {
          lastMessageText =
              TextUtils.fixArabicEncoding(chat['last_message_content']);
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
            lastMessageText = TextUtils.fixArabicEncoding(contentText);

            if (lastMsg.containsKey('created_at') &&
                lastMsg['created_at'] != null) {
              timestamp = lastMsg['created_at'];
            } else if (lastMsg.containsKey('timestamp') &&
                lastMsg['timestamp'] != null) {
              timestamp = lastMsg['timestamp'].toString();
            }
          }
        }

        // Add the isSheikh flag to the chat object
        return {
          ...chat,
          'name': name,
          'last_message_text': lastMessageText,
          'timestamp': timestamp,
          'is_sheikh': isSheikh, // Store if other participant is a sheikh
          'has_unread': _hasUnreadMessages(
              chat, _currentUserId), // Add flag for unread messages
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

  // Helper method to check if a chat has unread messages
  bool _hasUnreadMessages(Map<String, dynamic> chat, int? currentUserId) {
    // First, check the unread_count field which is the most direct way
    if (chat.containsKey('unread_count')) {
      final unreadCount = chat['unread_count'] as int? ?? 0;
      return unreadCount > 0;
    }

    // Fallback: check if last message is unread
    if (chat.containsKey('last_message') &&
        chat['last_message'] != null &&
        chat['last_message'] is Map) {
      final lastMessage = chat['last_message'] as Map<String, dynamic>;
      final senderId = lastMessage['sender_id']?.toString() ??
          lastMessage['sender']?.toString();
      final isRead = lastMessage['is_read'] == true;

      // If message is from someone else and not marked as read
      return !isRead &&
          senderId != null &&
          senderId != currentUserId.toString();
    }

    return false;
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
          TextUtils.fixArabicEncoding(lastMessage);
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
        title: TextUtils.fixArabicEncoding("جميع الرسائل"),
        showAddButton: false,
        showBackButton: true,
        onAddPressed: _showNewConversationDialog,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppStyles.lightPurple),
              ),
            )
          : (_chats == null || _chats!.isEmpty)
              ? _buildEmptyState()
              : _buildChatsList(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppStyles.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppStyles.lightPurple.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.chat_rounded,
                size: 60,
                color: AppStyles.lightPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              TextUtils.fixArabicEncoding('لا توجد محادثات بعد'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppStyles.darkPurple,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              TextUtils.fixArabicEncoding(
                  'ابدأ محادثة جديدة للتواصل مع الآخرين'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppStyles.greyShaded600,
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppStyles.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: AppStyles.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsList() {
    // Start animation when chats are loaded
    if (!_animationController.isCompleted) {
      _animationController.forward();
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: AppStyles.lightPurple,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: _chats!.length,
        itemBuilder: (context, index) {
          final chat = _chats![index];
          return _buildChatCard(chat, index);
        },
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat, int index) {
    // Staggered animation for list items
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        (index / (_chats?.length ?? 1)) * 0.4,
        min(1.0, (index / (_chats?.length ?? 1)) * 0.4 + 0.6),
        curve: Curves.easeOutQuart,
      ),
    );

    String messagePreview = chat['last_message_text'] ?? 'لا توجد رسائل';

    DateTime timestamp;
    try {
      final rawTimestamp = chat['timestamp'];
      if (rawTimestamp is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
      } else {
        timestamp = DateTime.parse(rawTimestamp.toString());
      }
    } catch (e) {
      timestamp = DateTime.now();
    }

    final formattedTime =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    final isSelected = widget.selectedChatId == chat['id'];
    final isSheikh = chat['is_sheikh'] == true;
    final hasUnread = chat['has_unread'] == true; // Get unread status

    // Generate only first letter of name for avatar - EDIT #1
    final String name = (chat['name'] ?? 'محادثة').toString();
    String initial = '?';

    if (name.isNotEmpty) {
      initial = name[0].toUpperCase();
    }

    // Use AppStyles.purple for all avatars - EDIT #2
    final avatarColor = AppStyles.lightPurple;

    return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(animation),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                if (widget.onChatSelected != null) {
                  widget.onChatSelected!(chat['id']);
                } else {
                  _navigateToChat(chat['id']);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppStyles.whitePurple : AppStyles.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppStyles.lightPurple.withOpacity(0.3)
                          : AppStyles.boxShadow.withOpacity(0.1),
                      blurRadius: isSelected ? 8 : 4,
                      spreadRadius: isSelected ? 1 : 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isSelected
                        ? AppStyles.lightPurple
                        : AppStyles.greyShaded300.withOpacity(0.5),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      // Avatar - MODIFIED for single letter and purple color
                      Hero(
                        tag: 'avatar_${chat['id']}',
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: avatarColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: avatarColor.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                            border: Border.all(
                              color: AppStyles.white,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        TextUtils.fixArabicEncoding(name),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? AppStyles.darkPurple
                                              : AppStyles.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isSheikh)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
                                          child: VerificationBadge(
                                            isVerifiedSheikh: true,
                                            size: 16.0,
                                            color: isSelected
                                                ? AppStyles.darkPurple
                                                : AppStyles.purple,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppStyles.lightPurple
                                            .withOpacity(0.15)
                                        : AppStyles.greyShaded100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? AppStyles.darkPurple
                                          : AppStyles.greyShaded600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (hasUnread) // Show unread indicator
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    _ensureProperEncoding(messagePreview),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: hasUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: hasUnread
                                          ? isSelected
                                              ? AppStyles.darkPurple
                                              : Colors.black87
                                          : isSelected
                                              ? AppStyles.purple
                                              : AppStyles.greyShaded600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ), // Unread message indicator at the end of the row
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(right: 2),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppStyles.buttonColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _showNewConversationDialog,
        backgroundColor: AppStyles.buttonColor,
        icon: const Icon(Icons.chat_bubble_outline, size: 20),
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            TextUtils.fixArabicEncoding('محادثة جديدة'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        elevation: 0,
      ),
    );
  }
}
