import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      body: Center(
        child: Text('Chat Page',
            style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
