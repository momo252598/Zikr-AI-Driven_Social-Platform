import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:software_graduation_project/screens/signup/signup.dart';
import '../../base/res/styles/app_styles.dart';

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
          const TextSpan(text: "ليس لديك حساب؟ "), // translated
          TextSpan(
            text: 'سجّل هنا', // translated link text
            style: TextStyle(
              color: AppStyles.txtFieldColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 250),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const SignUpScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ),
                );
              },
          ),
        ],
      ),
    );
  }
}
