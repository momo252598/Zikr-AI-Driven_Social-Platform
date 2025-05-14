import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Add kIsWeb import
import 'package:intl/intl.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/models/user.dart';
import 'package:software_graduation_project/services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneNumberController;
  // Bio controller removed
  late DateTime? _birthDate;
  String? _gender;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneNumberController =
        TextEditingController(text: widget.user.phoneNumber);
    _birthDate = widget.user.birthDate;
    _gender = _toArabicGender(widget.user.gender);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    // Bio controller disposal removed
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppStyles.txtFieldColor,
            colorScheme: ColorScheme.light(primary: AppStyles.txtFieldColor),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final Map<String, dynamic> updatedData = {
          'username': _usernameController.text,
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'phone_number': _phoneNumberController.text,
          'gender': _toEnglishGender(_gender),
        };

        // Only add birth_date if it exists
        if (_birthDate != null) {
          updatedData['birth_date'] =
              DateFormat('yyyy-MM-dd').format(_birthDate!);
        }

        final response = await _apiService.updateUserProfile(updatedData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
        );

        // Return to account settings page with updated user
        Navigator.pop(context, User.fromJson(response));
      } catch (e) {
        String errorMessage = 'فشل تحديث الملف الشخصي$e';

        // Check for username already exists error
        if (e.toString().toLowerCase().contains('username') &&
            e.toString().toLowerCase().contains('exist')) {
          errorMessage = 'اسم المستخدم مستخدم، الرجاء اختيار اسم آخر';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to convert English gender values to Arabic
  String? _toArabicGender(String? gender) {
    if (gender == null) return null;
    if (gender.toLowerCase() == 'male') return 'ذكر';
    if (gender.toLowerCase() == 'female') return 'أنثى';
    return gender;
  }

  // Helper method to convert Arabic gender values to English
  String? _toEnglishGender(String? gender) {
    if (gender == null) return null;
    if (gender == 'ذكر') return 'male';
    if (gender == 'أنثى') return 'female';
    return gender;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
          title: 'تعديل الملف الشخصي',
          showAddButton: false,
          showBackButton: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              // Center the content
              child: ConstrainedBox(
                // Add constraint box
                constraints: BoxConstraints(
                  maxWidth: kIsWeb
                      ? 600
                      : double.infinity, // Slightly narrower for forms
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username field
                        TextFormField(
                          controller: _usernameController,
                          textAlign: TextAlign.center, // Center align text
                          decoration: const InputDecoration(
                            labelText: 'اسم المستخدم',
                            border: OutlineInputBorder(),
                            // Center the hint/label
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال اسم المستخدم';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // First name field
                        TextFormField(
                          controller: _firstNameController,
                          textAlign: TextAlign.center, // Center align text
                          decoration: const InputDecoration(
                            labelText: 'الاسم الأول',
                            border: OutlineInputBorder(),
                            // Center the hint/label
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Last name field
                        TextFormField(
                          controller: _lastNameController,
                          textAlign: TextAlign.center, // Center align text
                          decoration: const InputDecoration(
                            labelText: 'الاسم الأخير',
                            border: OutlineInputBorder(),
                            // Center the hint/label
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phone number field
                        TextFormField(
                          controller: _phoneNumberController,
                          textAlign: TextAlign.center, // Center align text
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                            border: OutlineInputBorder(),
                            // Center the hint/label
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bio field removed

                        // Birth date picker
                        ListTile(
                          title: const Text('تاريخ الميلاد'),
                          subtitle: Text(_birthDate != null
                              ? DateFormat('yyyy-MM-dd').format(_birthDate!)
                              : 'غير محدد'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectDate(context),
                        ),
                        const Divider(),

                        // Gender selection
                        const Text(
                          'الجنس',
                          style: TextStyle(fontSize: 16),
                        ),
                        RadioListTile<String>(
                          title: const Text('ذكر'),
                          value: 'ذكر',
                          groupValue: _gender,
                          onChanged: (value) {
                            setState(() {
                              _gender = value;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('أنثى'),
                          value: 'أنثى',
                          groupValue: _gender,
                          onChanged: (value) {
                            setState(() {
                              _gender = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit button
                        Center(
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyles.txtFieldColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                            ),
                            child: Text(
                              'حفظ التغييرات',
                              style: TextStyle(
                                  fontSize: 16, color: AppStyles.white),
                            ),
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
