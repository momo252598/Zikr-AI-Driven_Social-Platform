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
            // Field title
            Text(
              'معلومات الحساب',
              style: TextStyle(
                color: AppStyles.darkPurple,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Email field with icon
            _buildInputField(
              controller: _emailController,
              hintText: 'البريد الإلكتروني',
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email_outlined,
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

            // Username field with icon
            _buildInputField(
              controller: _usernameController,
              hintText: 'اسم المستخدم',
              keyboardType: TextInputType.text,
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال اسم المستخدم';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password field
            _buildInputField(
              controller: _passwordController,
              hintText: 'كلمة المرور',
              icon: Icons.lock_outline,
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
            _buildInputField(
              controller: _confirmPasswordController,
              hintText: 'تأكيد كلمة المرور',
              icon: Icons.lock_outline,
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

            // Next button with gradient
            Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [AppStyles.buttonColor, AppStyles.darkPurple],
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
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'التالي',
                  style: TextStyle(
                    color: AppStyles.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required FormFieldValidator<String> validator,
    IconData? icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppStyles.boxShadow.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomTextField(
        controller: controller,
        hintText: hintText,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        suffixIcon: suffixIcon,
        prefixIcon: icon != null
            ? Icon(icon, color: AppStyles.white.withOpacity(0.7))
            : null,
        borderRadius: 12,
      ),
    );
  }
}
