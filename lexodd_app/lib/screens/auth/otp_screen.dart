// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../home/home_screen.dart';

class OTPScreen extends StatefulWidget {
  static const String routeName = '/otp';
  final String? email;
  final bool isPasswordReset;
  const OTPScreen({super.key, this.email, this.isPasswordReset = false});
  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isLoading = false;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) { _emailController.text = widget.email!; _sendOTP(); }
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendTimer > 0) { setState(() => _resendTimer--); return true; }
      return false;
    });
  }

  Future<void> _sendOTP() async {
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final sent = await auth.sendOTP(_emailController.text.trim(), purpose: widget.isPasswordReset ? 'password_reset' : 'login');
    setState(() { _isLoading = false; if (sent) { _otpSent = true; _resendTimer = 60; } });
    if (sent) { _startTimer(); _showSuccess('OTP sent to ${_emailController.text.trim()}'); }
    else { _showError(auth.errorMessage ?? 'Failed to send OTP'); }
  }

  Future<void> _verifyOTP() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) { _showError('Enter complete OTP'); return; }
    setState(() => _isLoading = true);
    if (widget.isPasswordReset) {
      setState(() { _otpVerified = true; _isLoading = false; });
    } else {
      final auth = context.read<AuthProvider>();
      final success = await auth.loginWithOTP(_emailController.text.trim(), otp);
      setState(() => _isLoading = false);
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      } else if (mounted) _showError(auth.errorMessage ?? 'Invalid OTP');
    }
  }

  Future<void> _resetPassword() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (_newPasswordController.text.length < 8) { _showError('Min 8 characters'); return; }
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(_emailController.text.trim(), otp, _newPasswordController.text);
    setState(() => _isLoading = false);
    if (success && mounted) { _showSuccess('Password reset! Login now.'); Navigator.pop(context); }
    else if (mounted) _showError('Reset failed');
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.successColor));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context))),
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF4)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 20),
            Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Icon(widget.isPasswordReset ? Iconsax.lock : Iconsax.sms, size: 40, color: AppTheme.primaryColor)),
            const SizedBox(height: 24),
            Text(widget.isPasswordReset ? 'Reset Password' : 'OTP Verification', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(!_otpSent ? 'Enter your email to receive OTP' : 'Enter code sent to\n${_emailController.text}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 40),
            if (!_otpSent) ...[
              TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Iconsax.sms), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 24),
              CustomButton(text: 'Send OTP', isLoading: _isLoading, onPressed: _sendOTP),
            ] else if (_otpSent && !_otpVerified) ...[
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(6, (i) => Container(
                width: 48, height: 56, margin: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(controller: _otpControllers[i], focusNode: _otpFocusNodes[i],
                  keyboardType: TextInputType.number, textAlign: TextAlign.center, maxLength: 1,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2))),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) { if (v.isNotEmpty && i < 5) {
                    _otpFocusNodes[i + 1].requestFocus();
                  } else if (v.isEmpty && i > 0) _otpFocusNodes[i - 1].requestFocus(); }),
              ))),
              const SizedBox(height: 24),
              _resendTimer > 0 ? Text('Resend in ${_resendTimer}s', style: const TextStyle(color: AppTheme.textSecondary))
                : TextButton(onPressed: () { setState(() => _resendTimer = 60); _sendOTP(); }, child: const Text('Resend OTP', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600))),
              const SizedBox(height: 24),
              CustomButton(text: 'Verify OTP', isLoading: _isLoading, onPressed: _verifyOTP),
            ] else if (_otpVerified && widget.isPasswordReset) ...[
              TextFormField(controller: _newPasswordController, obscureText: true,
                decoration: InputDecoration(labelText: 'New Password', prefixIcon: const Icon(Iconsax.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 24),
              CustomButton(text: 'Reset Password', isLoading: _isLoading, onPressed: _resetPassword),
            ],
          ]),
        ),
      ),
    );
  }
}
