import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _apiService.changePassword(
          _oldPasswordController.text,
          _newPasswordController.text,
          _confirmPasswordController.text,
        );

        // Show success message and go back to profile page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
        );
        Navigator.pop(context);
      } catch (e) {
        String errorMessage = 'فشل تغيير كلمة المرور';

        // Check for specific error messages
        if (e.toString().contains('Wrong password')) {
          errorMessage = 'كلمة المرور الحالية غير صحيحة';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'تغيير كلمة المرور',
        showAddButton: false,
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Current Password Field
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: _obscureOldPassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور الحالية',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureOldPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureOldPassword = !_obscureOldPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور الحالية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // New Password Field
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور الجديدة',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور الجديدة';
                        }
                        if (value.length < 8) {
                          return 'كلمة المرور يجب أن تكون على الأقل 8 أحرف';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور الجديدة',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء تأكيد كلمة المرور الجديدة';
                        }
                        if (value != _newPasswordController.text) {
                          return 'كلمات المرور غير متطابقة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.txtFieldColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          'تغيير كلمة المرور',
                          style:
                              TextStyle(fontSize: 16, color: AppStyles.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
