import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../base/res/styles/app_styles.dart';
import '../../services/auth_service.dart'; // Import AuthService

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

class _SignUpStepThreeState extends State<SignUpStepThree> {
  final _formKey = GlobalKey<FormState>();
  // Replace single controller with list of controllers
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  // Add focus nodes to manage focus
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  String? _errorMessage;
  final AuthService _authService = AuthService(); // Create AuthService instance
  late final String _baseUrl;

  @override
  void initState() {
    super.initState();
    // Set base URL based on platform
    final host = kIsWeb ? '127.0.0.1' : '192.168.1.19';
    _baseUrl = 'http://$host:8000';
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
            // Message about verification code
            Text(
              'تم إرسال رمز التحقق إلى بريدك الإلكتروني.',
              style: TextStyle(
                color: AppStyles.black,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'الرجاء إدخال الرمز المكون من 6 أرقام أدناه',
              style: TextStyle(
                color: AppStyles.black,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Replace with explicit LTR Row
            Directionality(
              textDirection: TextDirection.ltr, // Force left-to-right direction
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => Container(
                    width: 45,
                    height: 55,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextFormField(
                      controller: _codeControllers[index],
                      focusNode: _focusNodes[index],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppStyles.txtFieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppStyles.white,
                        fontSize: 24,
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
              ),
            ),
            const SizedBox(height: 10),

            // Add validation message for the entire code
            if (_codeControllers.any((controller) => controller.text.isEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'الرجاء إدخال جميع الأرقام الستة',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),

            // Resend code option
            TextButton(
              onPressed: _isLoading ? null : _resendVerificationCode,
              child: Text(
                'إعادة إرسال الرمز',
                style: TextStyle(
                  color: AppStyles.buttonColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyAndSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'تأكيد',
                      style: TextStyle(
                        color: AppStyles.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
