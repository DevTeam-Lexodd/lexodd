import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../home/home_screen.dart';

class OTPScreen extends StatefulWidget {
  static const String routeName = '/otp';
  final String? email;
  final bool isPasswordReset;
  final bool isEmailVerification;
  final bool displayAsDialog;
  final String? verificationToken;

  /// Called after a successful verification with the verificationToken that
  /// was actually verified. The token matters: it changes every time the user
  /// resends the OTP, and the signup request must carry the latest one.
  final ValueChanged<String>? onVerified;

  const OTPScreen({
    super.key,
    this.email,
    this.isPasswordReset = false,
    this.isEmailVerification = false,
    this.displayAsDialog = false,
    this.verificationToken,
    this.onVerified,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _otpSent = false;
  bool _isLoading = false;
  bool _timerActive = false;
  int _resendTimer = 60;
  String? _verificationToken;

  bool get _isDialog => widget.displayAsDialog || widget.onVerified != null;

  String get _purpose => widget.isPasswordReset
      ? 'password_reset'
      : widget.isEmailVerification
          ? 'email_verification'
          : 'login';

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!.trim();
    }
    if (widget.verificationToken != null) {
      _verificationToken = widget.verificationToken;
      _otpSent = true;
      _startTimer();
    } else if (widget.email != null && widget.email!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendOTP());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    if (_timerActive) return;
    _timerActive = true;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) {
        _timerActive = false;
        return false;
      }
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
        return true;
      }
      _timerActive = false;
      return false;
    });
  }

  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();
    if (!AppValidators.isValidEmail(email)) {
      AppSnackbar.error(context, 'Enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final token = await auth.sendOTP(email, purpose: _purpose);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (token == null) {
      AppSnackbar.error(context, auth.errorMessage ?? 'Unable to send OTP');
      return;
    }

    setState(() {
      _verificationToken = token;
      _otpSent = true;
      _resendTimer = 60;
      for (final controller in _otpControllers) {
        controller.clear();
      }
    });
    _startTimer();
    AppSnackbar.success(context, 'OTP sent to $email');
    _otpFocusNodes.first.requestFocus();
  }

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      AppSnackbar.error(context, 'Enter the complete 6-digit OTP');
      return;
    }
    if (_verificationToken == null) {
      AppSnackbar.error(context, 'Please request a new OTP');
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOTP(
      _emailController.text.trim(),
      otp,
      purpose: _purpose,
      verificationToken: _verificationToken!,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      AppSnackbar.error(context, auth.errorMessage ?? 'Invalid OTP');
      return;
    }

    // Hand control back to the caller (e.g. signup) together with the token
    // that was just verified - never a stale token captured before a resend.
    if (widget.onVerified != null) {
      widget.onVerified!(_verificationToken!);
      return;
    }

    if (_purpose == 'login') {
      // A session exists now - go home and drop the whole auth stack so the
      // back button cannot return to login/OTP screens.
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil(HomeScreen.routeName, (_) => false);
      return;
    }

    // email_verification without a callback: the user is NOT registered yet,
    // so there is no session and Home would be wrong. Just report success and
    // close, letting the caller continue its flow.
    AppSnackbar.success(context, 'Email verified');
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _resetPassword() async {
    final otp = _otpControllers.map((c) => c.text).join();
    final newPassword = _newPasswordController.text;
    if (otp.length != 6) {
      AppSnackbar.error(context, 'Enter the 6-digit OTP from your email');
      return;
    }
    if (!AppValidators.isStrongPassword(newPassword)) {
      AppSnackbar.error(context, 'Password needs min 8 chars, uppercase, lowercase and number');
      return;
    }
    if (_verificationToken == null) {
      AppSnackbar.error(context, 'Please request a new OTP');
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(
      _emailController.text.trim(),
      otp,
      newPassword,
      verificationToken: _verificationToken!,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      AppSnackbar.success(context, 'Password reset. Please login with the new password.');
      Navigator.of(context).pop();
    } else {
      AppSnackbar.error(context, auth.errorMessage ?? 'Password reset failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: _isDialog ? 24 : 44,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _buildContent(),
      ),
    );

    if (_isDialog) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: content,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final title = widget.isPasswordReset
        ? 'Reset Password'
        : widget.isEmailVerification
            ? 'Verify Email'
            : 'Login with OTP';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isDialog)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Close',
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(widget.isPasswordReset ? Iconsax.lock : Iconsax.sms,
                size: 38, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 22),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(
          !_otpSent
              ? 'Enter your email and we will send a secure 6-digit code.'
              : 'Enter the 6-digit code sent to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 28),
        if (!_otpSent) ...[
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Iconsax.sms),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onFieldSubmitted: (_) => _sendOTP(),
          ),
          const SizedBox(height: 20),
          CustomButton(text: 'Send OTP', isLoading: _isLoading, onPressed: _sendOTP),
        ] else ...[
          _otpFields(),
          const SizedBox(height: 12),
          const Text(
            "Didn't receive it? Check spam/junk or resend after the timer.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textHint),
          ),
          if (widget.isPasswordReset) ...[
            const SizedBox(height: 20),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Min 8 chars, upper, lower & number',
                prefixIcon: const Icon(Iconsax.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _resendTimer > 0
              ? Text('Resend in ${_resendTimer}s',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary))
              : TextButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  child: const Text('Resend OTP',
                      style: TextStyle(
                          color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                ),
          const SizedBox(height: 18),
          CustomButton(
            text: widget.isPasswordReset ? 'Reset Password' : 'Verify OTP',
            isLoading: _isLoading,
            onPressed: widget.isPasswordReset ? _resetPassword : _verifyOTP,
          ),
        ],
      ],
    );
  }

  Widget _otpFields() {
    return LayoutBuilder(builder: (context, constraints) {
      final gap = constraints.maxWidth < 360 ? 6.0 : 8.0;
      final boxWidth = (constraints.maxWidth - gap * 5) / 6;
      final boxHeight = boxWidth.clamp(44.0, 56.0).toDouble();
      return Row(
        children: List.generate(6, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index == 5 ? 0 : gap),
            child: SizedBox(
              width: boxWidth,
              height: boxHeight,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textInputAction: index == 5 ? TextInputAction.done : TextInputAction.next,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: TextStyle(
                  fontSize: boxWidth < 44 ? 18 : 22,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  } else if (index == 5 && value.isNotEmpty) {
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ),
          );
        }),
      );
    });
  }
}
