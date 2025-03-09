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
  final _allChatsKey = GlobalKey<State<AllChatsPage>>();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 250, maxWidth: 350),
          child: AllChatsPage(
            key: _allChatsKey,
            selectedChatId: selectedChatId,
            onChatSelected: (int chatId) {
              setState(() {
                selectedChatId = chatId;
              });
            },
          ),
        ),
        VerticalDivider(width: 3, color: AppStyles.txtFieldColor),
        Expanded(
          child: selectedChatId != null
              ? ChatPage(
                  key: ValueKey('chat-$selectedChatId'),
                  chatId: selectedChatId!,
                )
              : Container(
                  color: AppStyles.bgColor,
                  child: Center(
                      child: Text("إختر محادثة أو أنشئ رسالة جديدة!",
                          style: Theme.of(context).textTheme.displaySmall)),
                ),
        ),
      ],
    );
  }
}
