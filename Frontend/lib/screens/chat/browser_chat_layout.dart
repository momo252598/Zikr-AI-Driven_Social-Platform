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
  final GlobalKey<State<AllChatsPage>> _allChatsKey =
      GlobalKey<State<AllChatsPage>>();
  bool _isFullscreen = false; // Add fullscreen toggle state

  void _updateChat(int chatId, String message) {
    final currentState = _allChatsKey.currentState;
    if (currentState != null) {
      (currentState as dynamic).updateSpecificChat(chatId, message);
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!_isFullscreen)
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
        if (!_isFullscreen)
          VerticalDivider(width: 3, color: AppStyles.txtFieldColor),
        // --- Wrap the chat area in a Stack to overlay the fullscreen button above everything ---
        Expanded(
          child: Stack(
            children: [
              // Chat content
              Positioned.fill(
                child: selectedChatId != null
                    ? ChatPage(
                        key: ValueKey('chat-$selectedChatId'),
                        chatId: selectedChatId!,
                        onMessageUpdate: (String message) {
                          _updateChat(selectedChatId!, message);
                        },
                      )
                    : Container(
                        color: AppStyles.bgColor,
                        child: Center(
                            child: Text("إختر محادثة أو أنشئ رسالة جديدة!",
                                style:
                                    Theme.of(context).textTheme.displaySmall)),
                      ),
              ),
              // Fullscreen toggle button (always on top, with background for visibility)
              Positioned(
                top: 12,
                left: 12,
                child: Material(
                  color: Colors.black.withOpacity(0.12),
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    icon: Icon(
                        _isFullscreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white),
                    tooltip:
                        _isFullscreen ? 'إظهار جميع المحادثات' : 'ملء الشاشة',
                    onPressed: _toggleFullscreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BrowserChatLayoutInitialSelectedChat extends StatefulWidget {
  final int initialChatId;
  const BrowserChatLayoutInitialSelectedChat(
      {Key? key, required this.initialChatId})
      : super(key: key);

  @override
  State<BrowserChatLayoutInitialSelectedChat> createState() =>
      _BrowserChatLayoutInitialSelectedChatState();
}

class _BrowserChatLayoutInitialSelectedChatState
    extends State<BrowserChatLayoutInitialSelectedChat> {
  int? selectedChatId;
  final GlobalKey<State<AllChatsPage>> _allChatsKey =
      GlobalKey<State<AllChatsPage>>();
  bool _isFullscreen = false; // Add fullscreen toggle state

  @override
  void initState() {
    super.initState();
    selectedChatId = widget.initialChatId;
  }

  void _updateChat(int chatId, String message) {
    final currentState = _allChatsKey.currentState;
    if (currentState != null) {
      (currentState as dynamic).updateSpecificChat(chatId, message);
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!_isFullscreen)
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
        if (!_isFullscreen)
          VerticalDivider(width: 3, color: AppStyles.txtFieldColor),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: selectedChatId != null
                    ? ChatPage(
                        key: ValueKey('chat-$selectedChatId'),
                        chatId: selectedChatId!,
                        onMessageUpdate: (String message) {
                          _updateChat(selectedChatId!, message);
                        },
                      )
                    : Container(
                        color: AppStyles.bgColor,
                        child: Center(
                            child: Text("إختر محادثة أو أنشئ رسالة جديدة!",
                                style:
                                    Theme.of(context).textTheme.displaySmall)),
                      ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Material(
                  color: Colors.black.withOpacity(0.12),
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    icon: Icon(
                        _isFullscreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white),
                    tooltip:
                        _isFullscreen ? 'إظهار جميع المحادثات' : 'ملء الشاشة',
                    onPressed: _toggleFullscreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
