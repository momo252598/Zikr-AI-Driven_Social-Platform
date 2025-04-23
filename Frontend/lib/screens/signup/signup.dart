import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:software_graduation_project/components/signup/signup_step_one.dart';
import 'package:software_graduation_project/components/signup/signup_step_two.dart';
import 'package:software_graduation_project/components/signup/signup_step_three.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _currentStep = 0;
  String? _selectedGender;
  bool _isLoading = false;
  String? _errorMessage;
  late final String _baseUrl;

  @override
  void initState() {
    super.initState();
    // Set base URL based on platform
    final host = kIsWeb ? '127.0.0.1' : '192.168.1.9';
    _baseUrl = 'http://$host:8000';
  }

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

  void _nextStep() async {
    if (_currentStep == 1) {
      // Create account after step 2 is completed
      await _createAccount();
    } else {
      setState(() {
        if (_currentStep < 2) {
          _currentStep++;
        }
      });
    }
  }

  Future<void> _createAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Convert gender from Arabic to backend expected format
      if (_userData['gender'] == 'ذكر') {
        _userData['gender'] = 'male';
      } else if (_userData['gender'] == 'أنثى') {
        _userData['gender'] = 'female';
      }

      // Format data for API - match the exact field names expected by the backend
      final signupData = {
        'username': _userData['username'],
        'password': _userData['password'],
        'password2': _userData['password'],
        'email': _userData['email'],
        'user_type':
            _userData['account_type'], // Changed from account_type to user_type
        'phone_number': _userData['phone_number'],
        'birth_date':
            _userData['birthdate'], // Changed from birthdate to birth_date
        'first_name': _userData['first_name'],
        'last_name': _userData['last_name'],
        'gender': _userData['gender'],
      };

      // Log the data being sent for debugging
      print('Sending signup data: ${json.encode(signupData)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/accounts/signup/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(signupData),
      );

      // Log the full response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Account created successfully
        setState(() {
          _isLoading = false;
          _currentStep++; // Move to verification step
        });
      } else {
        // Parse error response and display more specific error
        Map<String, dynamic> errorData = {};
        try {
          errorData = json.decode(response.body);
        } catch (e) {
          print('Error parsing response: $e');
        }

        setState(() {
          _errorMessage = 'خطأ: ${errorData.toString()}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception during signup: $e');
      setState(() {
        _errorMessage =
            'حدث خطأ في الاتصال بالخادم. الرجاء المحاولة مرة أخرى.\nالخطأ: $e';
        _isLoading = false;
      });
    }
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
    // This will be called from step 3 when verification is complete
    // Navigate to skeleton page
    Navigator.pushReplacementNamed(context, '/skeleton');
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

                    // Error message for account creation
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Show a loading indicator when creating account
                    if (_isLoading)
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          CircularProgressIndicator(
                              color: AppStyles.buttonColor),
                          const SizedBox(height: 10),
                          Text(
                            'جاري إنشاء الحساب...',
                            style: TextStyle(
                              color: AppStyles.black,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    else
                    // Forms for different steps
                    if (_currentStep == 0)
                      SignUpStepOne(
                        userData: _userData,
                        onDataUpdated: _updateUserData,
                        onNext: _nextStep,
                      )
                    else if (_currentStep == 1)
                      SignUpStepTwo(
                        userData: _userData,
                        onDataUpdated: _updateUserData,
                        onNext: _nextStep,
                        onGenderChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      )
                    else if (_currentStep == 2)
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
