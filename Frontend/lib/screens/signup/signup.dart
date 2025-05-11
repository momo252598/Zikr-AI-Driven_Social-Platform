import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:software_graduation_project/components/signup/signup_step_one.dart';
import 'package:software_graduation_project/components/signup/signup_step_two.dart';
import 'package:software_graduation_project/components/signup/signup_step_three.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:software_graduation_project/utils/safe_animation_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  String? _selectedGender;
  bool _isLoading = false;
  String? _errorMessage;
  late final String _baseUrl;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Set base URL based on platform
    final host = kIsWeb ? '127.0.0.1' : '192.168.1.11';
    _baseUrl = 'http://$host:8000';

    _animationController = createSafeAnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        Uri.parse('$_baseUrl/api/accounts/signup/'),
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
        _animationController.reset();
        _animationController.forward();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppStyles.whitePurple,
              AppStyles.white,
            ],
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: FadeTransition(
            opacity: _animation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: kToolbarHeight + 10,
                  left: 32,
                  right: 32,
                  bottom: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon with animated container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppStyles.whitePurple,
                        boxShadow: [
                          BoxShadow(
                            color: AppStyles.lightPurple.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _selectedGender == 'أنثى'
                            ? FlutterIslamicIcons.muslimah2
                            : FlutterIslamicIcons.muslim2,
                        size: 120,
                        color: AppStyles.darkPurple,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title with decorative underline
                    Column(
                      children: [
                        Text(
                          'إنشاء حساب',
                          style: TextStyle(
                            color: AppStyles.darkPurple,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppStyles.lightPurple,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Modern step indicators with labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepIndicator(0, "الحساب"),
                          _buildStepConnector(0),
                          _buildStepIndicator(1, "معلومات"),
                          _buildStepConnector(1),
                          _buildStepIndicator(2, "التحقق"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Error message for account creation
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppStyles.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppStyles.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: AppStyles.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: AppStyles.red,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Show a loading indicator when creating account
                    if (_isLoading)
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          CircularProgressIndicator(
                              color: AppStyles.buttonColor),
                          const SizedBox(height: 16),
                          Text(
                            'جاري إنشاء الحساب...',
                            style: TextStyle(
                              color: AppStyles.darkPurple,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    else
                      // Forms for different steps with card container
                      Container(
                        decoration: BoxDecoration(
                          color: AppStyles.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppStyles.boxShadow.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: _currentStep == 0
                            ? SignUpStepOne(
                                userData: _userData,
                                onDataUpdated: _updateUserData,
                                onNext: _nextStep,
                              )
                            : _currentStep == 1
                                ? SignUpStepTwo(
                                    userData: _userData,
                                    onDataUpdated: _updateUserData,
                                    onNext: _nextStep,
                                    onGenderChanged: (value) {
                                      setState(() {
                                        _selectedGender = value;
                                        _animationController.reset();
                                        _animationController.forward();
                                      });
                                    },
                                  )
                                : SignUpStepThree(
                                    userData: _userData,
                                    onSubmit: _submitData,
                                  ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final bool isActive = _currentStep >= step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive ? AppStyles.buttonColor : AppStyles.whitePurple,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AppStyles.buttonColor : AppStyles.lightPurple,
                width: 2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppStyles.buttonColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: isActive
                  ? Icon(
                      _currentStep > step ? Icons.check : Icons.circle,
                      color: AppStyles.white,
                      size: _currentStep > step ? 20 : 12,
                    )
                  : Text(
                      (step + 1).toString(),
                      style: TextStyle(
                        color: AppStyles.lightPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppStyles.darkPurple : AppStyles.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final bool isActive = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      color: isActive
          ? AppStyles.buttonColor
          : AppStyles.lightPurple.withOpacity(0.3),
    );
  }
}
