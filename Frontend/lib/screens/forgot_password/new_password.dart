import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/services/password_reset_service.dart';
import 'dart:convert';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const NewPasswordScreen(
      {Key? key, required this.email, required this.resetToken})
      : super(key: key);

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  final AuthService _authService = AuthService();
  final PasswordResetService _passwordResetService = PasswordResetService();
  // No initState needed as we're using the PasswordResetService

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Use password reset service
        final result = await _passwordResetService.resetPassword(
          widget.email,
          widget.resetToken,
          _passwordController.text,
          _confirmPasswordController.text,
        );

        if (result['success']) {
          // Password reset successful, now login the user automatically
          final loginResult = await _authService.login(
            widget.email,
            _passwordController.text,
          );

          if (loginResult['success']) {
            // Navigate to home screen
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/skeleton', (route) => false);
          } else {
            // Show success message and navigate to login
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'تم إعادة تعيين كلمة المرور بنجاح. يرجى تسجيل الدخول.'),
              ),
            );
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
        } else {
          setState(() {
            _errorMessage = result['message'] ??
                'فشل في إعادة تعيين كلمة المرور. يرجى المحاولة مرة أخرى.';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Exception during password reset: $e');
        setState(() {
          _errorMessage = 'حدث خطأ في الاتصال بالخادم. يرجى المحاولة مرة أخرى.';
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
          'إعادة تعيين كلمة المرور',
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
                        // Title and instructions
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
                                Icons.lock_outline,
                                size: 60,
                                color: AppStyles.darkPurple,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'أدخل كلمة المرور الجديدة',
                                style: TextStyle(
                                  color: AppStyles.darkPurple,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'يرجى إدخال كلمة مرور جديدة وتأكيدها',
                                style: TextStyle(
                                  color: AppStyles.greyShaded600,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),

                              // New password field
                              TextFormField(
                                controller: _passwordController,
                                textAlign: TextAlign.center,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppStyles.txtFieldColor,
                                  hintText: 'كلمة المرور الجديدة',
                                  hintStyle: TextStyle(color: AppStyles.white),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppStyles.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 21,
                                    vertical: 15,
                                  ),
                                ),
                                style: TextStyle(color: AppStyles.white),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال كلمة المرور الجديدة';
                                  }
                                  if (value.length < 8) {
                                    return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Confirm password field
                              TextFormField(
                                controller: _confirmPasswordController,
                                textAlign: TextAlign.center,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppStyles.txtFieldColor,
                                  hintText: 'تأكيد كلمة المرور',
                                  hintStyle: TextStyle(color: AppStyles.white),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppStyles.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 21,
                                    vertical: 15,
                                  ),
                                ),
                                style: TextStyle(color: AppStyles.white),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء تأكيد كلمة المرور';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'كلمات المرور غير متطابقة';
                                  }
                                  return null;
                                },
                              ),

                              // Error message
                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 20),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppStyles.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppStyles.red.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: AppStyles.red,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              const SizedBox(height: 20),

                              // Submit button
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton(
                                      onPressed: _resetPassword,
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
                                        'تغيير كلمة المرور',
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
