import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../base/res/styles/app_styles.dart';
import '../../services/auth_service.dart'; // Import AuthService
import 'package:software_graduation_project/utils/safe_animation_controller.dart';

class SignUpStepThree extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onSubmit;

  const SignUpStepThree({
    Key? key,
    required this.userData,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _SignUpStepThreeState createState() => _SignUpStepThreeState();
}

class _SignUpStepThreeState extends State<SignUpStepThree>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  String? _errorMessage;
  final AuthService _authService = AuthService();
  late final String _baseUrl;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Set base URL based on platform
    final host = kIsWeb ? '127.0.0.1' : '192.168.1.11';
    _baseUrl = 'http://$host:8000';

    _animationController = createSafeAnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Set up focus listeners for animation effects
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  // Get the combined verification code from all controllers
  String get _verificationCode => _codeControllers.map((e) => e.text).join();

  Future<void> _verifyAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        print(
            'Attempting to verify account with email: ${widget.userData['email']}');
        print('Using verification token: ${_verificationCode}');

        // Only verify the account since it has already been created
        final verifyResponse = await http.post(
          Uri.parse('$_baseUrl/api/accounts/api/verify-account/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'email': widget.userData['email'],
            'token': _verificationCode,
          }),
        );

        print('Verification response status: ${verifyResponse.statusCode}');
        print('Verification response body: ${verifyResponse.body}');

        if (verifyResponse.statusCode == 200) {
          // Verification successful, now login the user
          await _loginUser();
        } else {
          // Handle verification error
          setState(() {
            _errorMessage = 'رمز التحقق غير صحيح. الرجاء المحاولة مرة أخرى.';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Exception during verification: $e');
        // If account is verified in the database despite the error, try to login anyway
        bool loginSuccess = await _loginUser(ignoreErrors: true);

        if (!loginSuccess) {
          setState(() {
            _errorMessage =
                'حدث خطأ في الاتصال بالخادم. الرجاء المحاولة مرة أخرى.';
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<bool> _loginUser({bool ignoreErrors = false}) async {
    try {
      print(
          'Attempting to login with username: ${widget.userData['username']}');

      // Use AuthService login method instead of direct HTTP request
      final response = await _authService.login(
          widget.userData['email'], widget.userData['password']);

      print('Login response: $response');

      if (response['success']) {
        print('Login successful! Redirecting to skeleton page.');

        // Proceed with signup completion and navigation
        Navigator.of(context).pushReplacementNamed('/skeleton');
        return true;
      } else if (!ignoreErrors) {
        setState(() {
          _errorMessage = 'فشل تسجيل الدخول: ${response['message']}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception during login: $e');
      if (!ignoreErrors) {
        setState(() {
          _errorMessage =
              'حدث خطأ أثناء محاولة تسجيل الدخول. الرجاء المحاولة مرة أخرى.';
          _isLoading = false;
        });
      }
    }
    return false;
  }

  Future<void> _resendVerificationCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/accounts/api/resend-verification/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': widget.userData['email'],
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رمز جديد إلى بريدك الإلكتروني'),
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              'فشل في إعادة إرسال رمز التحقق. الرجاء المحاولة مرة أخرى.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في الاتصال بالخادم. الرجاء المحاولة مرة أخرى.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title with verification icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user,
                  color: AppStyles.darkPurple,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'التحقق من الحساب',
                  style: TextStyle(
                    color: AppStyles.darkPurple,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Message about verification code with better styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppStyles.whitePurple,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppStyles.lightPurple.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.email_outlined, color: AppStyles.darkPurple),
                      const SizedBox(width: 8),
                      Text(
                        'تم إرسال رمز التحقق إلى:',
                        style: TextStyle(
                          color: AppStyles.darkPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userData['email'] ?? '',
                    style: TextStyle(
                      color: AppStyles.buttonColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الرجاء إدخال الرمز المكون من 6 أرقام أدناه',
                    style: TextStyle(
                      color: AppStyles.greyShaded600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Verification code input with animation
            Directionality(
              textDirection: TextDirection.ltr,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          6,
                          (index) => Container(
                            width: 40, // Reduced from 45 to 40
                            height: 50, // Slightly reduced from 55 to 50
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3), // Reduced margin from 4 to 3
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: _focusNodes[index].hasFocus
                                      ? AppStyles.buttonColor.withOpacity(0.3)
                                      : AppStyles.boxShadow.withOpacity(0.1),
                                  blurRadius: _focusNodes[index].hasFocus
                                      ? 6
                                      : 3, // Reduced blur radius
                                  spreadRadius: _focusNodes[index].hasFocus
                                      ? 1
                                      : 0, // Reduced spread
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _codeControllers[index],
                              focusNode: _focusNodes[index],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _focusNodes[index].hasFocus
                                    ? AppStyles.buttonColor
                                    : AppStyles.txtFieldColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      10), // Slightly reduced from 12
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppStyles.white,
                                fontSize: 22, // Slightly reduced from 24
                                fontWeight: FontWeight.bold,
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              buildCounter: (context,
                                      {required currentLength,
                                      required isFocused,
                                      maxLength}) =>
                                  null,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  // Move to next field
                                  if (index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else {
                                    // Last field - hide keyboard
                                    FocusScope.of(context).unfocus();
                                  }
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      );
                    }),
              ),
            ),
            const SizedBox(height: 10),

            // Add validation message for the entire code
            if (_codeControllers.any((controller) => controller.text.isEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'الرجاء إدخال جميع الأرقام الستة',
                  style: TextStyle(color: AppStyles.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            // Error message with better styling
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
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
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Didn't receive code text
            Text(
              'لم تستلم الرمز؟',
              style: TextStyle(
                color: AppStyles.greyShaded600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Resend code button with better styling
            TextButton.icon(
              onPressed: _isLoading ? null : _resendVerificationCode,
              icon: Icon(
                Icons.refresh,
                color: AppStyles.buttonColor,
              ),
              label: Text(
                'إعادة إرسال الرمز',
                style: TextStyle(
                  color: AppStyles.buttonColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 30),

            // Submit button with gradient
            Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [AppStyles.grey, AppStyles.grey]
                      : [AppStyles.buttonColor, AppStyles.darkPurple],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppStyles.buttonColor.withOpacity(0.4),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تأكيد الحساب',
                            style: TextStyle(
                              color: AppStyles.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.verified, color: AppStyles.white),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
