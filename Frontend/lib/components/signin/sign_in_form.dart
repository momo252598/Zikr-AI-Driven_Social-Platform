import 'package:flutter/material.dart';
import 'dart:convert';
import '../../base/res/styles/app_styles.dart';
import '../../services/auth_service.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignInFormState createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeErrorOverlay();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Hide any existing error message when attempting login
    _removeErrorOverlay();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.login(
          _emailController.text,
          _passwordController.text,
        );

        if (result['success']) {
          print('Login successful');
          // Navigate to the skeleton page
          Navigator.of(context).pushReplacementNamed('/skeleton');
        } else {
          // Determine the error message
          String errorMessage;
          if (result['statusCode'] == 400 || result['statusCode'] == 401) {
            errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
          } else {
            errorMessage =
                result['message'] ?? 'فشل تسجيل الدخول، يرجى المحاولة مرة أخرى';
          }

          // Show error as overlay
          _showErrorSnackBar(errorMessage);
          print('Login failed: ${result['message']}');
        }
      } catch (e) {
        // Show error as overlay
        _showErrorSnackBar('حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى');
        print('Login exception: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to show error in fixed position overlay
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    // Remove any existing overlay first
    _removeErrorOverlay();

    // Create a new overlay entry with absolute positioning
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 215, // Fixed position from top of screen
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Insert the overlay into the current context
    Overlay.of(context).insert(_overlayEntry!);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), _removeErrorOverlay);
  }

  void _removeErrorOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                // textDirection: TextDirection.rtl,
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                ),
                style: TextStyle(color: AppStyles.white),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 31),
              TextFormField(
                controller: _passwordController,
                // textDirection: TextDirection.rtl, // set RTL direction
                textAlign: TextAlign.center, // added alignment
                obscureText: _obscureText,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppStyles.txtFieldColor,
                  hintText: 'كلمة المرور', // translated hint
                  hintStyle: TextStyle(color: AppStyles.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  // Moved IconButton from suffixIcon to prefixIcon
                  prefixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppStyles.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 21, vertical: 15),
                ),
                style: TextStyle(color: AppStyles.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 44),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          color: AppStyles.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              // Add Forgot Password link
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                child: Text(
                  'نسيت كلمة المرور؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppStyles.txtFieldColor,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
