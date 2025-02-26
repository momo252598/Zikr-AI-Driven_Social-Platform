import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      // ...existing app bar or other widgets...
      body: Center(
        child: Text('الصفحة الرئيسية',
            style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
