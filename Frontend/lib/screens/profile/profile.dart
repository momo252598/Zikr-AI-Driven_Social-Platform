import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      body: Center(
        child: Text('Profile Page',
            style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
