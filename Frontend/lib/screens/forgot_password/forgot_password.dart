import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/screens/forgot_password/reset_code.dart';
import 'package:software_graduation_project/services/password_reset_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final PasswordResetService _passwordResetService = PasswordResetService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final result = await _passwordResetService.requestPasswordReset(
          _emailController.text,
        );

        if (result['success']) {
          // Navigate to the reset code screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetCodeScreen(
                email: _emailController.text,
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage =
                result['message'] ?? 'حدث خطأ. يرجى المحاولة مرة أخرى.';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage =
              'حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final contentWidth = isLargeScreen ? 500.0 : screenWidth * 0.9;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'نسيت كلمة المرور',
          style: TextStyle(
            color: AppStyles.darkPurple,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: AppStyles.bgColor,
        width: double.infinity,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 24.0,
                  horizontal: isLargeScreen ? 24.0 : 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Container(
                    width: contentWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppStyles.whitePurple,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: AppStyles.boxShadow.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lock_reset,
                                size: 60,
                                color: AppStyles.darkPurple,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'أدخل بريدك الإلكتروني',
                                style: TextStyle(
                                  color: AppStyles.darkPurple,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'سنرسل لك رمز تحقق لإعادة تعيين كلمة المرور',
                                style: TextStyle(
                                  color: AppStyles.greyShaded600,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              TextFormField(
                                controller: _emailController,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppStyles.txtFieldColor,
                                  hintText: 'البريد الإلكتروني',
                                  hintStyle: TextStyle(color: AppStyles.white),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 25, vertical: 15),
                                ),
                                style: TextStyle(color: AppStyles.white),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال البريد الإلكتروني';
                                  }
                                  // Basic email validation
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'الرجاء إدخال بريد إلكتروني صحيح';
                                  }
                                  return null;
                                },
                              ),

                              // Display error message if exists
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: AppStyles.red,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              const SizedBox(height: 30),
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton(
                                      onPressed: _requestPasswordReset,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppStyles.buttonColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        minimumSize:
                                            const Size(double.infinity, 50),
                                      ),
                                      child: Text(
                                        'إرسال رمز التحقق',
                                        style: TextStyle(
                                          color: AppStyles.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
