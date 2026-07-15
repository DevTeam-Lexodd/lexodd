// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;

  const CustomButton({super.key, required this.text, this.onPressed, this.isLoading = false, this.isExpanded = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: isExpanded ? double.infinity : null, height: 54,
      child: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]),
        child: ElevatedButton(onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))));
  }
}
