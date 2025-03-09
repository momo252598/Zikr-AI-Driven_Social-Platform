import 'package:flutter/material.dart';
import 'package:software_graduation_project/screens/chat/chat.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';

class SkeletonWithChat extends StatelessWidget {
  final int chatId;
  const SkeletonWithChat({Key? key, required this.chatId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "تطبيق القرآن الكريم",
        showAddButton: false,
        showBackButton: false,
      ),
      body: ChatPage(chatId: chatId),
      // Optionally include bottomNavigationBar if needed
    );
  }
}
