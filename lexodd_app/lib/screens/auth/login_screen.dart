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
                  // Email
                  CustomTextField(controller: _emailController, label: 'Email', hint: 'Enter your email',
                    prefixIcon: Iconsax.sms, keyboardType: TextInputType.emailAddress,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email'; return null; }),
                  const SizedBox(height: 16),
                  // Password
                  CustomTextField(controller: _passwordController, label: 'Password', hint: 'Enter password',
                    prefixIcon: Iconsax.lock, obscureText: _obscurePassword,
                    suffixIcon: IconButton(icon: Icon(_obscurePassword ? Iconsax.eye_slash : Iconsax.eye, color: AppTheme.textHint),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; return null; }),
                  Align(alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OTPScreen(isPasswordReset: true))),
                      child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryColor)))),
                  const SizedBox(height: 24),
                  CustomButton(text: 'Sign In', isLoading: auth.isLoading, onPressed: _handleLogin),
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