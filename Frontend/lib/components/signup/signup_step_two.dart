import 'package:flutter/material.dart';
import '../../base/res/styles/app_styles.dart';
import '../../base/widgets/text_field_form.dart';

class SignUpStepTwo extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onDataUpdated;
  final VoidCallback onNext;
  final ValueChanged<String?>? onGenderChanged;

  const SignUpStepTwo({
    Key? key,
    required this.userData,
    required this.onDataUpdated,
    required this.onNext,
    this.onGenderChanged,
  }) : super(key: key);

  @override
  _SignUpStepTwoState createState() => _SignUpStepTwoState();
}

class _SignUpStepTwoState extends State<SignUpStepTwo> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedGender;
  String _accountType = 'regular';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data if any
    _firstNameController.text = widget.userData['first_name'] ?? '';
    _lastNameController.text = widget.userData['last_name'] ?? '';
    _birthDateController.text = widget.userData['birthdate'] ?? '';
    _phoneController.text = widget.userData['phone_number'] ?? '';

    // Ensure the gender value is one of the valid options
    final gender = widget.userData['gender'];
    _selectedGender = (gender == 'ذكر' || gender == 'أنثى') ? gender : null;

    _accountType = widget.userData['account_type'] ?? 'regular';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppStyles.buttonColor,
              onPrimary: AppStyles.white,
              onSurface: AppStyles.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // First Name & Last Name Row
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _firstNameController,
                    hintText: 'الاسم الأول',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال الاسم الأول';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    controller: _lastNameController,
                    hintText: 'اسم العائلة',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال اسم العائلة';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Birth date field
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: CustomTextField(
                  controller: _birthDateController,
                  hintText: 'تاريخ الميلاد',
                  suffixIcon:
                      Icon(Icons.calendar_today, color: AppStyles.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال تاريخ الميلاد';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Phone Number
            CustomTextField(
              controller: _phoneController,
              hintText: 'رقم الهاتف',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال رقم الهاتف';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Gender dropdown
            DropdownButtonFormField<String>(
              value: (_selectedGender == 'ذكر' || _selectedGender == 'أنثى')
                  ? _selectedGender
                  : null,
              alignment: Alignment.centerLeft,
              style: TextStyle(color: AppStyles.white),
              selectedItemBuilder: (BuildContext context) {
                return ['ذكر', 'أنثى'].map((String value) {
                  return Text(value, style: TextStyle(color: AppStyles.white));
                }).toList();
              },
              icon: Icon(Icons.arrow_drop_down, color: AppStyles.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppStyles.txtFieldColor,
                hintText: 'الجنس',
                hintStyle: TextStyle(color: AppStyles.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              items: [
                DropdownMenuItem(
                  value: 'ذكر',
                  child: Text('ذكر', style: TextStyle(color: AppStyles.black)),
                ),
                DropdownMenuItem(
                  value: 'أنثى',
                  child: Text('أنثى', style: TextStyle(color: AppStyles.black)),
                ),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
                widget.onGenderChanged?.call(newValue);
              },
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'الرجاء اختيار الجنس';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Account Type
            Row(
              children: [
                Text(
                  'نوع الحساب:',
                  style: TextStyle(
                    color: AppStyles.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'regular',
                        groupValue: _accountType,
                        activeColor: AppStyles.buttonColor,
                        onChanged: (String? value) {
                          setState(() {
                            _accountType = value!;
                          });
                        },
                      ),
                      Text('مستخدم', style: TextStyle(color: AppStyles.black)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'sheikh',
                        groupValue: _accountType,
                        activeColor: AppStyles.buttonColor,
                        onChanged: (String? value) {
                          setState(() {
                            _accountType = value!;
                          });
                        },
                      ),
                      Text('شيخ', style: TextStyle(color: AppStyles.black)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Next button
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Update user data and go to next step
                  widget.onDataUpdated({
                    'first_name': _firstNameController.text,
                    'last_name': _lastNameController.text,
                    'birthdate': _birthDateController.text,
                    'phone_number': _phoneController.text,
                    'gender': _selectedGender,
                    'account_type': _accountType,
                  });
                  widget.onNext();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'التالي',
                style: TextStyle(
                  color: AppStyles.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
