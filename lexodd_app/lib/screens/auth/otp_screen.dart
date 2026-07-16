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
  final bool isEmailVerification;
  final String? verificationToken;
  final VoidCallback? onVerified; // Callback when verification succeeds

  const OTPScreen({
    super.key,
    this.email,
    this.isPasswordReset = false,
    this.isEmailVerification = false,
    this.verificationToken,
    this.onVerified,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  bool _timerActive = false;
  int _resendTimer = 60;
  String? _verificationToken;

  String get _purpose => widget.isPasswordReset
      ? 'password_reset'
      : widget.isEmailVerification
          ? 'email_verification'
          : 'login';

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
    if (widget.verificationToken != null) {
      _verificationToken = widget.verificationToken;
      _otpSent = true;
      _startTimer();
    } else if (widget.email != null) {
      _sendOTP();
    }
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
    if (_timerActive) return; // guard against overlapping countdown loops
    _timerActive = true;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) { _timerActive = false; return false; }
      if (_resendTimer > 0) { setState(() => _resendTimer--); return true; }
      _timerActive = false;
      return false;
    });
  }

  Future<void> _sendOTP() async {
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final verificationToken = await auth.sendOTP(_emailController.text.trim(), purpose: _purpose);
    setState(() { _isLoading = false; if (verificationToken != null) { _verificationToken = verificationToken; _otpSent = true; _resendTimer = 60; } });
    if (verificationToken != null) { _startTimer(); _showSuccess('OTP sent to ${_emailController.text.trim()}'); }
    else { _showError(auth.errorMessage ?? 'Failed to send OTP'); }
  }

  Future<void> _verifyOTP() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) { _showError('Enter complete OTP'); return; }
    if (_verificationToken == null) { _showError('Request a new OTP'); return; }
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOTP(
      _emailController.text.trim(), otp,
      purpose: _purpose, verificationToken: _verificationToken!,
    );
    setState(() => _isLoading = false);
    if (success && mounted) {
      // Call the callback if provided (for dialog usage)
      if (widget.onVerified != null) {
        widget.onVerified!();
      } else {
        // Navigate to home screen for standalone page usage
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      }
    } else if (mounted) {
      _showError(auth.errorMessage ?? 'Invalid OTP');
    }
  }

  // Password reset verifies the OTP on the backend together with the new
  // password, so the OTP + new password are submitted in a single step.
  Future<void> _resetPassword() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) { _showError('Enter the 6-digit OTP from your email'); return; }
    if (_newPasswordController.text.length < 8) { _showError('Password must be at least 8 characters'); return; }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(_newPasswordController.text)) {
      _showError('Password needs uppercase, lowercase & a number'); return;
    }
    if (_verificationToken == null) { _showError('Request a new OTP'); return; }
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(_emailController.text.trim(), otp, _newPasswordController.text, verificationToken: _verificationToken!);
    setState(() => _isLoading = false);
    if (success && mounted) { _showSuccess('Password reset! Login now.'); Navigator.pop(context); }
    else if (mounted) _showError(auth.errorMessage ?? 'Reset failed. Check the OTP and try again.');
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.successColor));

  @override
  Widget build(BuildContext context) {
    final isDialog = widget.onVerified != null;
    
    return isDialog
        ? Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildContent(),
            ),
          )
        : Scaffold(
            appBar: AppBar(leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context))),
            body: Container(
              width: double.infinity, height: double.infinity,
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF4)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildContent(),
              ),
            ),
          );
  }

  Widget _buildContent() {
    final isDialog = widget.onVerified != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDialog) const SizedBox(height: 20),
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
          ] else if (_otpSent) ...[
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
            if (widget.isPasswordReset) ...[
              const SizedBox(height: 24),
              TextFormField(controller: _newPasswordController, obscureText: true,
                decoration: InputDecoration(labelText: 'New Password', hintText: 'Min 8 chars, upper, lower & number', prefixIcon: const Icon(Iconsax.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            ],
            const SizedBox(height: 24),
            _resendTimer > 0 ? Text('Resend in ${_resendTimer}s', style: const TextStyle(color: AppTheme.textSecondary))
              : TextButton(onPressed: () { setState(() => _resendTimer = 60); _sendOTP(); }, child: const Text('Resend OTP', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600))),
            const SizedBox(height: 24),
            CustomButton(
              text: widget.isPasswordReset ? 'Reset Password' : 'Verify OTP',
              isLoading: _isLoading,
              onPressed: widget.isPasswordReset ? _resetPassword : _verifyOTP),
          ],
        ],
      ),
    );
  }
}