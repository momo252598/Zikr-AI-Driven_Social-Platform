import 'package:flutter/material.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';

class SocialSignIn extends StatelessWidget {
  const SocialSignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Implement social sign in logic here
      },
      child: Icon(
        FluentSystemIcons.ic_fluent_mail_add_filled,
        color: AppStyles.lightPurple,
        size: 30,
      ),
    );
  }
}
