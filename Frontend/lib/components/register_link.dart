import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class RegisterLink extends StatelessWidget {
  const RegisterLink({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'Poppins',
          color: Colors.black,
        ),
        children: [
          const TextSpan(text: "Don't have an account? "),
          TextSpan(
            text: 'Register here',
            style: const TextStyle(
              color: Color(0xFF0E18F6),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // Navigate to registration page
              },
          ),
        ],
      ),
    );
  }
}
