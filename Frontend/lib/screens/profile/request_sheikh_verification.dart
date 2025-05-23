import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/components/signup/signup_sheikh_verify.dart';
import 'package:software_graduation_project/models/user.dart';
import 'package:software_graduation_project/services/sheikh_verification_service.dart';

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
  bool _isLoading = true;
  String? _errorMessage;
  final _sheikhService = SheikhVerificationService();
  bool _hasPendingRequest = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _checkExistingRequests();
  }

  // Check if user already has a pending verification request
  Future<void> _checkExistingRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasPending =
          await _sheikhService.hasExistingPendingVerification(_user.id);

      setState(() {
        _hasPendingRequest = hasPending;
        _isLoading = false;

        if (hasPending) {
          _errorMessage =
              'لديك بالفعل طلب توثيق قيد المراجعة. يرجى الانتظار حتى يتم مراجعة طلبك الحالي قبل تقديم طلب جديد.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء التحقق من حالة طلبات التوثيق السابقة.';
      });
    }
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
              else if (_isLoading)
                // Show loading indicator while checking requests
                Column(
                  children: [
                    CircularProgressIndicator(color: AppStyles.buttonColor),
                    const SizedBox(height: 16),
                    Text(
                      'جاري التحقق من حالة طلبات التوثيق السابقة...',
                      style: TextStyle(
                        color: AppStyles.darkPurple,
                        fontSize: 15,
                      ),
                    ),
                  ],
                )
              else if (_hasPendingRequest)
                // Message indicating pending request
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange[700], size: 32),
                      const SizedBox(height: 12),
                      Text(
                        'لديك بالفعل طلب توثيق قيد المراجعة',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى الانتظار حتى يتم مراجعة طلبك الحالي قبل تقديم طلب جديد.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[100],
                          foregroundColor: Colors.orange[800],
                        ),
                        child: const Text('العودة'),
                      ),
                    ],
                  ),
                )
              else
                // Use the SignUpSheikhVerify component
                SignUpSheikhVerify(
                  userData: userData,
                  onNext: _onVerificationCompleted,
                  onSkip: _onSkipVerification,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
