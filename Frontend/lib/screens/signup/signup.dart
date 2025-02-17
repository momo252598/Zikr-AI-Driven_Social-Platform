import 'package:flutter/material.dart';
import 'package:software_graduation_project/components/signup/sign_up_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

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
            // physics: const NeverScrollableScrollPhysics(),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF010001),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SignUpForm(),
                  // Stack(
                  //   alignment: Alignment.topCenter,
                  //   children: [
                  //     ColorFiltered(
                  //       colorFilter: ColorFilter.mode(
                  //         const Color.fromARGB(255, 135, 62, 213)
                  //             .withOpacity(0.1),
                  //         BlendMode.srcATop,
                  //       ),
                  //       child: Image.asset(
                  //         'assets/images/mosque.png', // Replace with your image path
                  //         fit: BoxFit.cover,
                  //         width: double.infinity,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
