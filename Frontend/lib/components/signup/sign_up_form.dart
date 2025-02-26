import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:software_graduation_project/base/res/media.dart';
import '../../base/res/styles/app_styles.dart';
import '../../base/widgets/text_field_form.dart'; // new import

class SignUpForm extends StatefulWidget {
  final ValueChanged<String?>? onGenderChanged; // new parameter

  const SignUpForm({super.key, this.onGenderChanged});

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each field
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // New gender variable
  String? _selectedGender;

  // New state variable for password visibility
  bool _obscurePassword = true;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse(
            'http://10.0.2.2:8000/api/signup/'), // Replace with your Django backend endpoint
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'gender': _selectedGender ?? '',
        }),
      );

      if (response.statusCode == 200) {
        // Handle successful sign up
        print('Sign up successful');
      } else {
        // Handle error response
        print('Sign up failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mimic the style from the sign-in page
    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // First Name & Last Name Row using CustomTextField
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _firstNameController,
                    hintText: 'الاسم الأول', // translated hint
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ادخل الاسم الأول'; // translated error
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    controller: _lastNameController,
                    hintText: 'اسم العائلة', // translated hint
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ادخل اسم العائلة'; // translated error
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Username
            CustomTextField(
              controller: _usernameController,
              hintText: 'اسم المستخدم', // translated hint
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'ادخل اسم المستخدم'; // translated error
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Email
            CustomTextField(
              controller: _emailController,
              hintText: 'البريد الإلكتروني', // translated hint
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'ادخل البريد الإلكتروني'; // translated error
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Password field with show/hide functionality using CustomTextField
            CustomTextField(
              controller: _passwordController,
              hintText: 'كلمة المرور', // translated hint
              obscureText: _obscurePassword, // updated
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
                if (value == null || value.isEmpty)
                  return 'ادخل كلمة المرور'; // translated error
                return null;
              },
            ),
            const SizedBox(height: 20),
            // New Gender field with updated dropdown menu text color and arrow icon color
            DropdownButtonFormField<String>(
              value: _selectedGender,
              alignment: Alignment.centerLeft,
              style: TextStyle(color: AppStyles.white),
              selectedItemBuilder: (BuildContext context) {
                return ['ذكر', 'أنثى'].map((String value) {
                  return Text(value, style: TextStyle(color: AppStyles.white));
                }).toList();
              },
              icon: Icon(Icons.arrow_drop_down,
                  color: AppStyles.white), // arrow icon color set to white
              decoration: InputDecoration(
                filled: true,
                fillColor: AppStyles.txtFieldColor,
                hintText: 'الجنس', // translated hint
                hintStyle: TextStyle(color: AppStyles.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              items: [
                DropdownMenuItem(
                  value: 'ذكر',
                  child: Text('ذكر', style: TextStyle(color: AppStyles.black)),
                ),
                DropdownMenuItem(
                  value: 'أنثى',
                  child: Text('أنثى', style: TextStyle(color: AppStyles.black)),
                ),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
                widget.onGenderChanged?.call(newValue); // propagate the change
              },
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'اختر الجنس'; // translated error
                return null;
              },
            ),
            const SizedBox(height: 30),
            // const Spacer(),
            // Sign Up button
            ElevatedButton(
              onPressed: _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'إنشاء حساب', // translated button text
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
    );
  }
}
