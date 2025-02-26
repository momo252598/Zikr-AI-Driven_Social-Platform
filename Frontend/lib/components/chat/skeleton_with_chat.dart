import 'package:flutter/material.dart';
import 'package:software_graduation_project/screens/chat/chat.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';

class SkeletonWithChat extends StatelessWidget {
  final int chatId;
  const SkeletonWithChat({Key? key, required this.chatId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: AppStyles.white), // changed back arrow color to white
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        ),
        centerTitle: true,
        title: Text(
          "تطبيق القرآن الكريم", // translated title
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: AppStyles.white,
          ),
        ),
      ),
      body: ChatPage(chatId: chatId),
      // Optionally include bottomNavigationBar if needed
    );
  }
}
