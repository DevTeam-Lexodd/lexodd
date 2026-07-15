import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await context.read<AuthProvider>().init();
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    Navigator.of(context).pushReplacementNamed(
      auth.isAuthenticated ? HomeScreen.routeName : LoginScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.business_center_rounded, size: 50, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            const Text('Lexodd', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Lexodd Hypernova System', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
            const SizedBox(height: 60),
            SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.8))),
            ),
            const SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
