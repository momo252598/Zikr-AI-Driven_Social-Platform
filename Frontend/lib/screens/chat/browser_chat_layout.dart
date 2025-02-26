import 'package:flutter/material.dart';
import 'package:software_graduation_project/screens/chat/chat.dart';
import 'all_chats.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';

class BrowserChatLayout extends StatefulWidget {
  const BrowserChatLayout({Key? key}) : super(key: key);

  @override
  _BrowserChatLayoutState createState() => _BrowserChatLayoutState();
}

class _BrowserChatLayoutState extends State<BrowserChatLayout> {
  int? selectedChatId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 250, maxWidth: 350),
          child: AllChatsPage(
            onChatSelected: (int chatId) {
              setState(() {
                selectedChatId = chatId;
              });
            },
          ),
        ),
        VerticalDivider(width: 1, color: AppStyles.grey),
        Expanded(
          child: selectedChatId != null
              ? ChatPage(chatId: selectedChatId!)
              : Center(
                  child: Text("Select a chat, or start a new one!",
                      style: Theme.of(context).textTheme.displaySmall)),
        )
      ],
    );
  }
}
