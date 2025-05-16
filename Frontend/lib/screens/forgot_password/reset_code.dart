import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/screens/forgot_password/new_password.dart';
import 'package:software_graduation_project/utils/safe_animation_controller.dart';
import 'package:software_graduation_project/services/password_reset_service.dart';

class ResetCodeScreen extends StatefulWidget {
  final String email;

  const ResetCodeScreen({Key? key, required this.email}) : super(key: key);

  @override
  _ResetCodeScreenState createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends State<ResetCodeScreen>
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
  final PasswordResetService _passwordResetService = PasswordResetService();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = createSafeAnimationController(
      duration: const Duration(milliseconds: 500),
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

  Future<void> _verifyAndProceed() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        print('Verifying reset code for email: ${widget.email}');
        print('Reset verification code: ${_verificationCode}');

        final result = await _passwordResetService.verifyResetCode(
          widget.email,
          _verificationCode,
        );

        if (result['success']) {
          // Reset code verification successful, navigate to password reset screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPasswordScreen(
                email: widget.email,
                resetToken: _verificationCode,
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = result['message'] ??
                'رمز التحقق غير صحيح. الرجاء المحاولة مرة أخرى.';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Exception during verification: $e');
        setState(() {
          _errorMessage =
              'حدث خطأ في الاتصال بالخادم. الرجاء المحاولة مرة أخرى.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendVerificationCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the password reset service to request a new code
      final result =
          await _passwordResetService.requestPasswordReset(widget.email);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رمز جديد إلى بريدك الإلكتروني'),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ??
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final contentWidth = isLargeScreen ? 500.0 : screenWidth * 0.9;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'التحقق من الرمز',
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
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: isLargeScreen ? 24.0 : 16.0,
                  ),
                  child: Container(
                    width: contentWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                                  Icon(Icons.email_outlined,
                                      color: AppStyles.darkPurple),
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
                                widget.email,
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
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AnimatedBuilder(
                                  animation: _animation,
                                  builder: (context, child) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        6,
                                        (index) => Container(
                                          width: 40,
                                          height: 50,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 3),
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    _focusNodes[index].hasFocus
                                                        ? AppStyles.buttonColor
                                                            .withOpacity(0.3)
                                                        : AppStyles.boxShadow
                                                            .withOpacity(0.1),
                                                blurRadius:
                                                    _focusNodes[index].hasFocus
                                                        ? 6
                                                        : 3,
                                                spreadRadius:
                                                    _focusNodes[index].hasFocus
                                                        ? 1
                                                        : 0,
                                              ),
                                            ],
                                          ),
                                          child: TextFormField(
                                            controller: _codeControllers[index],
                                            focusNode: _focusNodes[index],
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor:
                                                  _focusNodes[index].hasFocus
                                                      ? AppStyles.buttonColor
                                                      : AppStyles.txtFieldColor,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppStyles.white,
                                              fontSize: 22,
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
                                                  _focusNodes[index + 1]
                                                      .requestFocus();
                                                } else {
                                                  // Last field - hide keyboard
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                }
                                              }
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
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
                        ),
                        const SizedBox(height: 10),

                        // Add validation message for the entire code
                        if (_codeControllers
                            .any((controller) => controller.text.isEmpty))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'الرجاء إدخال جميع الأرقام الستة',
                              style:
                                  TextStyle(color: AppStyles.red, fontSize: 13),
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

                        const SizedBox(height: 30),

                        // Submit button
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _verifyAndProceed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppStyles.buttonColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: Text(
                                  'التحقق والمتابعة',
                                  style: TextStyle(
                                    color: AppStyles.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                        const SizedBox(height: 15),

                        // Resend code option
                        TextButton(
                          onPressed:
                              _isLoading ? null : _resendVerificationCode,
                          child: Text(
                            'إعادة إرسال الرمز',
                            style: TextStyle(
                              color: AppStyles.darkPurple,
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
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
