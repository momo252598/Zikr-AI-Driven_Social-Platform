import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../base/res/styles/app_styles.dart';

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
  final TextEditingController _verificationCodeController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Verify the code first
        final verifyResponse = await http.post(
          Uri.parse('http://10.0.2.2:8000/api/verify-email/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'email': widget.userData['email'],
            'code': _verificationCodeController.text,
          }),
        );

        if (verifyResponse.statusCode == 200) {
          // Then complete the signup process with all collected data
          final signupResponse = await http.post(
            Uri.parse('http://10.0.2.2:8000/api/signup/'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(widget.userData),
          );

          if (signupResponse.statusCode == 200) {
            // Signup successful
            widget.onSubmit();
          } else {
            // Handle signup error
            setState(() {
              _errorMessage =
                  'حدث خطأ أثناء إنشاء الحساب. الرجاء المحاولة مرة أخرى.';
              _isLoading = false;
            });
          }
        } else {
          // Handle verification error
          setState(() {
            _errorMessage = 'رمز التحقق غير صحيح. الرجاء المحاولة مرة أخرى.';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage =
              'حدث خطأ في الاتصال بالخادم. الرجاء المحاولة مرة أخرى.';
          _isLoading = false;
        });
      }
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

            // Verification code field
            TextFormField(
              controller: _verificationCodeController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppStyles.txtFieldColor,
                hintText: 'رمز التحقق',
                hintStyle: TextStyle(color: AppStyles.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppStyles.white,
                fontSize: 24,
                letterSpacing: 8,
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال رمز التحقق';
                } else if (value.length != 6) {
                  return 'رمز التحقق يجب أن يتكون من 6 أرقام';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),

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
              onPressed: () {
                // Add resend code functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال رمز جديد إلى بريدك الإلكتروني'),
                  ),
                );
              },
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
