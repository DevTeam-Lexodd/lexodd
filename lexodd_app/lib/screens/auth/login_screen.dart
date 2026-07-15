import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _useOTPLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailController.text.trim(), _passwordController.text);
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } else if (mounted) {
      _showError(auth.errorMessage ?? 'Login failed');
    }
  }

  Future<void> _handleOTPLogin() async {
    if (_emailController.text.trim().isEmpty) { _showError('Enter your email'); return; }
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OTPScreen(email: _emailController.text.trim())));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF4)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                  // Logo
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]),
                    child: const Icon(Icons.business_center_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  const Text('Welcome Back!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Sign in to continue', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 40),
                  // Toggle
                  Container(
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() => _useOTPLogin = false),
                        child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: !_useOTPLogin ? AppTheme.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text('Password', style: TextStyle(color: !_useOTPLogin ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600)))),
                      )),
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() => _useOTPLogin = true),
                        child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: _useOTPLogin ? AppTheme.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text('OTP', style: TextStyle(color: _useOTPLogin ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600)))),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 32),
                  // Email
                  CustomTextField(controller: _emailController, label: 'Email', hint: 'Enter your email',
                    prefixIcon: Iconsax.sms, keyboardType: TextInputType.emailAddress,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email'; return null; }),
                  const SizedBox(height: 16),
                  // Password
                  if (!_useOTPLogin)
                    CustomTextField(controller: _passwordController, label: 'Password', hint: 'Enter password',
                      prefixIcon: Iconsax.lock, obscureText: _obscurePassword,
                      suffixIcon: IconButton(icon: Icon(_obscurePassword ? Iconsax.eye_slash : Iconsax.eye, color: AppTheme.textHint),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                      validator: (v) { if (!_useOTPLogin && (v == null || v.isEmpty)) return 'Required'; return null; }),
                  if (!_useOTPLogin)
                    Align(alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OTPScreen(isPasswordReset: true))),
                        child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryColor)))),
                  const SizedBox(height: 24),
                  CustomButton(text: _useOTPLogin ? 'Send OTP' : 'Sign In', isLoading: auth.isLoading,
                    onPressed: _useOTPLogin ? _handleOTPLogin : _handleLogin),
                  const SizedBox(height: 32),
                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: AppTheme.textHint))),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ]),
                  const SizedBox(height: 32),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("Don't have an account? ", style: TextStyle(color: AppTheme.textSecondary)),
                    GestureDetector(onTap: () => Navigator.pushNamed(context, SignupScreen.routeName),
                      child: const Text('Sign Up', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600))),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


//in this give a option that employee can add there profile pic through using uploading pic from gallery or using camera and that should store in my database create that also in backend and i saw a blunder that after signup the next thing is verfiy otp email is alerady feteched from the signup from but the screen shows only email and send otp and otp is sent to that particular email but where that otp will be verify where the otp screen coming up?? and and one more thing after sending the otp to the email/outlook why it is not coming in inbox of the given email?? first given process after my command contiune to create or fix that