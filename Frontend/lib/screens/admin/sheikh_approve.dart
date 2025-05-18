import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';

class SheikhApprovePage extends StatefulWidget {
  const SheikhApprovePage({Key? key}) : super(key: key);

  @override
  _SheikhApprovePageState createState() => _SheikhApprovePageState();
}

class _SheikhApprovePageState extends State<SheikhApprovePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              size: 80,
              color: AppStyles.lightPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'صفحة توثيق الشيوخ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppStyles.darkPurple,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'هذه الصفحة ستحتوي على إجراءات توثيق حسابات الشيوخ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
