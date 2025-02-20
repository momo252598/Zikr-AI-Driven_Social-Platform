import 'package:flutter/material.dart';
import 'package:software_graduation_project/components/signin/sign_in_form.dart';
import 'package:software_graduation_project/components/signin/register_link.dart';
import 'package:software_graduation_project/base/res/media.dart';
import '../../base/res/styles/app_styles.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            color: AppStyles.bgColor,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: AppStyles.boxShadow,
                blurRadius: 100,
                offset: const Offset(40, 40),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100, // Set the desired width
                    height: 100, // Set the desired height
                    child: Image.asset(
                      AppMedia.quran, // Replace with your image path
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(height: 53),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF010001),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SignInForm(),
                  // const SizedBox(height: 36),
                  // const SizedBox(height: 30),
                  ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 500, minWidth: 400),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Image.asset(
                          AppMedia.mosque, // Replace with your image path
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        const Column(
                          children: [
                            SizedBox(height: 20),
                            RegisterLink(),
                          ],
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
    );
  }
}
