import 'package:flutter/material.dart';
import 'package:software_graduation_project/components/signup/sign_up_form.dart';
import 'package:software_graduation_project/base/res/media.dart';
import '../../base/res/styles/app_styles.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String? _selectedGender; // track selected gender

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // extend background behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppStyles.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background image covers whole screen
          Container(
            decoration: const BoxDecoration(
                // image: DecorationImage(
                // image: AssetImage(AppMedia.pattern2),
                // fit: BoxFit.cover,
                // colorFilter: ColorFilter.mode(
                //   Colors.black.withOpacity(0.2), // adjust opacity as needed
                //   BlendMode.darken,
                // ),
                // ),
                ),
          ),
          // Foreground content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                top: kToolbarHeight + 10, // leave space for AppBar
                left: 32,
                right: 32,
                bottom: 11,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Change icon based on selected gender
                  Icon(
                    _selectedGender == 'Female'
                        ? FlutterIslamicIcons.muslimah2
                        : FlutterIslamicIcons.muslim2,
                    size: 200,
                    color: AppStyles.black,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppStyles.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SignUpForm(
                    onGenderChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
