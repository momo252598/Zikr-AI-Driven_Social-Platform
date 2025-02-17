import 'package:flutter/material.dart';
import 'package:fluentui_icons/fluentui_icons.dart';

class SocialSignIn extends StatelessWidget {
  const SocialSignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Implement social sign in logic here
      },
      child: const Icon(
        FluentSystemIcons.ic_fluent_mail_add_filled,
        color: Color.fromARGB(255, 135, 62, 213),
        size: 30,
      ),
    );
  }
}
