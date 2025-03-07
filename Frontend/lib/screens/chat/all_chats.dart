import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';
import 'package:software_graduation_project/skeleton.dart';
import 'chat.dart'; // added import for ChatPage
import 'package:software_graduation_project/components/chat/skeleton_with_chat.dart'; // added import

class AllChatsPage extends StatefulWidget {
  final void Function(int)? onChatSelected; // new optional callback
  const AllChatsPage({Key? key, this.onChatSelected}) : super(key: key);

  @override
  _AllChatsPageState createState() => _AllChatsPageState();
}

class _AllChatsPageState extends State<AllChatsPage> {
  Future<List<dynamic>> _loadChats() async {
    // Load sample data from JSON asset
    final jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/utils/chat_ex.json');
    List<dynamic> chats = json.decode(jsonString);
    // sort chats, newest first
    chats.sort((a, b) => DateTime.parse(b['timestamp'])
        .compareTo(DateTime.parse(a['timestamp'])));
    return chats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: AppBar(
        title: Text(
          'جميع الرسائل',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: AppStyles.white,
          ),
        ),
        centerTitle: true,
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
        ), // translated title
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: AppStyles.white,
            ),
            onPressed: () {
              // New chat functionality to be implemented later
            },
          )
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppStyles.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _loadChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading chats'));
          }
          final chats = snapshot.data!;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final timestamp = DateTime.parse(chat['timestamp']);
              final formattedTime =
                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppStyles.lightPurple, width: 1),
                  ),
                  elevation: 3,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      chat['name'],
                      style: Theme.of(context).textTheme.titleMedium,
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
                            builder: (context) => ChatPage(chatId: chat['id']),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
