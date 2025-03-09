import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';
import 'package:software_graduation_project/skeleton.dart';
import 'chat.dart';
import 'package:software_graduation_project/components/chat/skeleton_with_chat.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';

class AllChatsPage extends StatefulWidget {
  final void Function(int)? onChatSelected;
  final int? selectedChatId; // Added parameter to track selected chat

  const AllChatsPage({Key? key, this.onChatSelected, this.selectedChatId})
      : super(key: key);

  @override
  _AllChatsPageState createState() => _AllChatsPageState();
}

class _AllChatsPageState extends State<AllChatsPage> {
  List<dynamic>? _chats;
  bool _isLoading = true;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      // Load sample data from JSON asset
      final jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/utils/chat_ex.json');
      final loadedChats = json.decode(jsonString) as List<dynamic>;

      // Sort chats, newest first
      loadedChats.sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));

      if (mounted) {
        setState(() {
          _chats = loadedChats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading chats: $e');
      if (mounted) {
        setState(() {
          _chats = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: const CustomAppBar(
        title: "جميع الرسائل",
        showAddButton: true,
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_chats == null || _chats!.isEmpty)
              ? const Center(child: Text('لا توجد محادثات'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _chats!.length,
                  itemBuilder: (context, index) {
                    final chat = _chats![index];
                    final timestamp = DateTime.parse(chat['timestamp']);
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
                                ? AppStyles
                                    .darkPurple // Darker border for selected chat
                                : AppStyles.lightPurple,
                            width: isSelected
                                ? 2
                                : 1, // Thicker border for selected chat
                          ),
                        ),
                        color: isSelected
                            ? AppStyles.whitePurple
                            : null, // Light background for selected chat
                        elevation: isSelected
                            ? 5
                            : 3, // Higher elevation for selected chat
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          title: Text(
                            chat['name'],
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
                            chat['lastMessage'],
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
    );
  }
}
