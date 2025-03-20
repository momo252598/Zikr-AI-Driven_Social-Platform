import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:software_graduation_project/components/signup/signup_step_one.dart';
import 'package:software_graduation_project/components/signup/signup_step_two.dart';
import 'package:software_graduation_project/components/signup/signup_step_three.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _currentStep = 0;
  String? _selectedGender;

  // User data that will be collected throughout the signup process
  final Map<String, dynamic> _userData = {
    'email': '',
    'username': '',
    'password': '',
    'first_name': '',
    'last_name': '',
    'birthdate': '',
    'phone_number': '',
    'gender': '',
    'account_type': 'regular', // default value
  };

  void _nextStep() {
    setState(() {
      if (_currentStep < 2) {
        _currentStep++;
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  void _updateUserData(Map<String, dynamic> data) {
    setState(() {
      _userData.addAll(data);
      if (data.containsKey('gender')) {
        _selectedGender = data['gender'];
      }
    });
  }

  void _submitData() {
    // This will be called from step 3 when validation is complete
    // Navigate to home page
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppStyles.trans,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppStyles.black),
                onPressed: _previousStep,
              )
            : IconButton(
                icon: Icon(Icons.arrow_back, color: AppStyles.black),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: kToolbarHeight + 10,
                  left: 32,
                  right: 32,
                  bottom: 11,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon changes based on gender selection
                    Icon(
                      _selectedGender == 'أنثى'
                          ? FlutterIslamicIcons.muslimah2
                          : FlutterIslamicIcons.muslim2,
                      size: 200,
                      color: AppStyles.black,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          color: AppStyles.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Step indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 3; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _currentStep
                                  ? AppStyles.buttonColor
                                  : AppStyles.txtFieldColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    // Forms for different steps
                    if (_currentStep == 0)
                      SignUpStepOne(
                        userData: _userData,
                        onDataUpdated: _updateUserData,
                        onNext: _nextStep,
                      ),
                    if (_currentStep == 1)
                      SignUpStepTwo(
                        userData: _userData,
                        onDataUpdated: _updateUserData,
                        onNext: _nextStep,
                        onGenderChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                    if (_currentStep == 2)
                      SignUpStepThree(
                        userData: _userData,
                        onSubmit: _submitData,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
