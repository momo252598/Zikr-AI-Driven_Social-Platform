import 'package:flutter/material.dart';
import 'dart:convert';
import '../../base/res/styles/app_styles.dart';
import '../../services/auth_service.dart';
// You might need to add your navigation import here
// import 'package:go_router/go_router.dart'; or flutter navigation

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
  String? _errorMessage;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
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
          // Or if using go_router:
          // context.go('/skeleton');
        } else {
          setState(() {
            _errorMessage =
                result['message'] ?? 'Login failed, please try again';
          });
          print('Login failed: ${result['message']}');
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: $e';
        });
        print('Login exception: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: _emailController,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
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
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 31),
                  TextFormField(
                    controller: _passwordController,
                    textDirection: TextDirection.rtl, // set RTL direction
                    textAlign: TextAlign.right, // added alignment
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
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppStyles.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 21, vertical: 15),
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
