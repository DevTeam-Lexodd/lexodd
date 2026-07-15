import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label, hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText, readOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;

  const CustomTextField({super.key, this.controller, this.label, this.hint, this.prefixIcon, this.suffixIcon,
    this.obscureText = false, this.keyboardType, this.validator, this.onTap, this.readOnly = false,
    this.textCapitalization = TextCapitalization.none});

  @override
  Widget build(BuildContext context) {
    return TextFormField(controller: controller, obscureText: obscureText, keyboardType: keyboardType,
      validator: validator, onTap: onTap, readOnly: readOnly, textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: AppTheme.textHint) : null,
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.errorColor)),
        filled: true, fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)));
  }
}
