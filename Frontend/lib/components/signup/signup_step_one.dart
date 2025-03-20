import 'package:flutter/material.dart';
import '../../base/res/styles/app_styles.dart';
import '../../base/widgets/text_field_form.dart';

class SignUpStepOne extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onDataUpdated;
  final VoidCallback onNext;

  const SignUpStepOne({
    Key? key,
    required this.userData,
    required this.onDataUpdated,
    required this.onNext,
  }) : super(key: key);

  @override
  _SignUpStepOneState createState() => _SignUpStepOneState();
}

class _SignUpStepOneState extends State<SignUpStepOne> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data if any
    _emailController.text = widget.userData['email'] ?? '';
    _usernameController.text = widget.userData['username'] ?? '';
    _passwordController.text = widget.userData['password'] ?? '';
    _confirmPasswordController.text = widget.userData['password'] ?? '';
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
            // Email field
            CustomTextField(
              controller: _emailController,
              hintText: 'البريد الإلكتروني',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال البريد الإلكتروني';
                } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'الرجاء إدخال بريد إلكتروني صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Username field
            CustomTextField(
              controller: _usernameController,
              hintText: 'اسم المستخدم',
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال اسم المستخدم';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password field
            CustomTextField(
              controller: _passwordController,
              hintText: 'كلمة المرور',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppStyles.white,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال كلمة المرور';
                } else if (value.length < 6) {
                  return 'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Confirm Password field
            CustomTextField(
              controller: _confirmPasswordController,
              hintText: 'تأكيد كلمة المرور',
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppStyles.white,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء تأكيد كلمة المرور';
                } else if (value != _passwordController.text) {
                  return 'كلمة المرور غير متطابقة';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            // Next button
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Update user data and go to next step
                  widget.onDataUpdated({
                    'email': _emailController.text,
                    'username': _usernameController.text,
                    'password': _passwordController.text,
                  });
                  widget.onNext();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'التالي',
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
