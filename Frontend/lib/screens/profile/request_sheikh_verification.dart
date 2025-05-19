import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/components/signup/signup_sheikh_verify.dart';
import 'package:software_graduation_project/models/user.dart';

class RequestSheikhVerificationPage extends StatefulWidget {
  final User user;

  const RequestSheikhVerificationPage({Key? key, required this.user})
      : super(key: key);

  @override
  _RequestSheikhVerificationPageState createState() =>
      _RequestSheikhVerificationPageState();
}

class _RequestSheikhVerificationPageState
    extends State<RequestSheikhVerificationPage> {
  late User _user;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  // Handle verification completion
  void _onVerificationCompleted() {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم تقديم طلب التحقق بنجاح. سيتم مراجعة طلبك خلال 24-48 ساعة.',
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
      ),
    );

    // Simply return to previous screen
    Navigator.pop(context);
  }

  // Handle skip verification
  void _onSkipVerification() {
    Navigator.pop(context); // Just go back without changes
  }

  @override
  Widget build(BuildContext context) {
    // Convert user data to map for the verification component
    final Map<String, dynamic> userData = {
      'id': _user.id,
      'email': _user.email,
      'name': _user.name,
    };

    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: const CustomAppBar(
        title: 'طلب التحقق كشيخ',
        showAddButton: false,
        showBackButton: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Display error message if any
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppStyles.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppStyles.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppStyles.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppStyles.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),

              // Show loading indicator when submitting
              if (_isSubmitting)
                Column(
                  children: [
                    CircularProgressIndicator(color: AppStyles.buttonColor),
                    const SizedBox(height: 16),
                    Text(
                      'جاري معالجة طلبك...',
                      style: TextStyle(
                        color: AppStyles.darkPurple,
                        fontSize: 15,
                      ),
                    ),
                  ],
                )
              else
                // Use the SignUpSheikhVerify component
                SignUpSheikhVerify(
                  userData: userData,
                  onNext: _onVerificationCompleted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
