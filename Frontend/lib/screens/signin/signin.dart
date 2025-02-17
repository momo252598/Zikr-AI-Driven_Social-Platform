import 'package:flutter/material.dart';
import 'package:software_graduation_project/components/signin/sign_in_form.dart';
import 'package:software_graduation_project/components/signin/register_link.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 247, 247, 247),
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 100,
                offset: Offset(40, 40),
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
                      'assets/images/quran.png', // Replace with your image path
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(height: 53),
                  const Align(
                    alignment: Alignment.centerLeft,
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
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          const Color.fromARGB(255, 135, 62, 213)
                              .withOpacity(0.1),
                          BlendMode.srcATop,
                        ),
                        child: Image.asset(
                          'assets/images/mosque.png', // Replace with your image path
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      const Column(
                        children: [
                          // SizedBox(height: 20),
                          // SocialSignIn(),
                          SizedBox(height: 20),
                          RegisterLink(),
                        ],
                      ),
                    ],
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
