import 'package:flutter/material.dart';
import '../res/styles/app_styles.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final double? borderRadius;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: AppStyles.white),
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppStyles.txtFieldColor,
        hintText: hintText,
        labelText: labelText,
        hintStyle: TextStyle(color: AppStyles.white.withOpacity(0.7)),
        labelStyle: TextStyle(color: AppStyles.white),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 10),
          borderSide:
              BorderSide(color: AppStyles.white.withOpacity(0.3), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 10),
          borderSide: BorderSide(color: AppStyles.red, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
