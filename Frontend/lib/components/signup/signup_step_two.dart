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
        // Format date as YYYY-MM-DD for backend compatibility
        _birthDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
            // Section title
            Text(
              'المعلومات الشخصية',
              style: TextStyle(
                color: AppStyles.darkPurple,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // First Name & Last Name Row
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _firstNameController,
                    hintText: 'الاسم الأول',
                    icon: Icons.person_outline,
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
                  child: _buildInputField(
                    controller: _lastNameController,
                    hintText: 'اسم العائلة',
                    icon: Icons.person_outline,
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
                child: _buildInputField(
                  controller: _birthDateController,
                  hintText: 'تاريخ الميلاد',
                  icon: Icons.calendar_today_outlined,
                  suffixIcon:
                      Icon(Icons.arrow_drop_down, color: AppStyles.white),
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
            _buildInputField(
              controller: _phoneController,
              hintText: 'رقم الهاتف',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال رقم الهاتف';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Gender dropdown with improved styling
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppStyles.txtFieldColor,
                boxShadow: [
                  BoxShadow(
                    color: AppStyles.boxShadow.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: (_selectedGender == 'ذكر' || _selectedGender == 'أنثى')
                    ? _selectedGender
                    : null,
                alignment: Alignment.centerRight,
                style: TextStyle(color: AppStyles.white),
                selectedItemBuilder: (BuildContext context) {
                  return ['ذكر', 'أنثى'].map((String value) {
                    return Text(value,
                        style: TextStyle(color: AppStyles.white));
                  }).toList();
                },
                icon: Icon(Icons.arrow_drop_down, color: AppStyles.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.transparent,
                  hintText: 'الجنس',
                  hintStyle: TextStyle(color: AppStyles.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  prefixIcon: Icon(Icons.person_outline,
                      color: AppStyles.white.withOpacity(0.7)),
                ),
                dropdownColor: AppStyles.lightPurple,
                borderRadius: BorderRadius.circular(10),
                items: [
                  DropdownMenuItem(
                    value: 'ذكر',
                    child:
                        Text('ذكر', style: TextStyle(color: AppStyles.white)),
                  ),
                  DropdownMenuItem(
                    value: 'أنثى',
                    child:
                        Text('أنثى', style: TextStyle(color: AppStyles.white)),
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
            ),
            const SizedBox(height: 24),

            // Account Type with improved styling
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                color: AppStyles.whitePurple,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppStyles.lightPurple.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نوع الحساب:',
                    style: TextStyle(
                      color: AppStyles.darkPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRadioOption(
                        value: 'regular',
                        groupValue: _accountType,
                        label: 'مستخدم',
                        onChanged: (value) {
                          setState(() {
                            _accountType = value!;
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      _buildRadioOption(
                        value: 'sheikh',
                        groupValue: _accountType,
                        label: 'شيخ',
                        onChanged: (value) {
                          setState(() {
                            _accountType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Next button with gradient
            Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [AppStyles.buttonColor, AppStyles.darkPurple],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppStyles.buttonColor.withOpacity(0.4),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Ensure birthdate is properly formatted
                    final birthdate = _selectedDate != null
                        ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
                        : _birthDateController.text;

                    // Update user data and go to next step
                    widget.onDataUpdated({
                      'first_name': _firstNameController.text,
                      'last_name': _lastNameController.text,
                      'birthdate': birthdate,
                      'phone_number': _phoneController.text,
                      'gender': _selectedGender,
                      'account_type': _accountType,
                    });
                    widget.onNext();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'التالي',
                  style: TextStyle(
                    color: AppStyles.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required FormFieldValidator<String> validator,
    IconData? icon,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppStyles.boxShadow.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomTextField(
        controller: controller,
        hintText: hintText,
        keyboardType: keyboardType,
        validator: validator,
        suffixIcon: suffixIcon,
        prefixIcon: icon != null
            ? Icon(icon, color: AppStyles.white.withOpacity(0.7))
            : null,
        borderRadius: 12,
      ),
    );
  }

  Widget _buildRadioOption(
      {required String value,
      required String groupValue,
      required String label,
      required ValueChanged<String?> onChanged}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color:
                groupValue == value ? AppStyles.buttonColor : AppStyles.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: groupValue == value
                  ? AppStyles.buttonColor
                  : AppStyles.grey.withOpacity(0.3),
            ),
            boxShadow: groupValue == value
                ? [
                    BoxShadow(
                      color: AppStyles.buttonColor.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                groupValue == value
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: groupValue == value ? AppStyles.white : AppStyles.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color:
                      groupValue == value ? AppStyles.white : AppStyles.black,
                  fontWeight:
                      groupValue == value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
