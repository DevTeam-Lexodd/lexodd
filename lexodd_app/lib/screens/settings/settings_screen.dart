import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../config/constant.dart';
import '../../services/auth_service.dart';
import '../../utils/app_snackbar.dart';
import '../auth/login_screen.dart';
import '../profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  static const String routeName = '/settings';
  final AuthService _authService = AuthService();
  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<AuthProvider>().employee;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Settings'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Profile Card
            Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8))
                    ]),
                child: Row(children: [
                  Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(
                          child: Text(employee?.initials ?? 'U',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(employee?.fullName ?? 'User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                        Text(employee?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13)),
                      ])),
                  IconButton(
                      icon: const Icon(Iconsax.edit, color: Colors.white),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()))),
                ])),
            const SizedBox(height: 24),
            _sectionTitle('Account'),
            _tile(
                context,
                Iconsax.user,
                'My Profile',
                'View profile',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()))),
            _tile(context, Iconsax.lock, 'Change Password', 'Update password',
                () => _showChangePassword(context)),
            _tile(
                context,
                Iconsax.sms,
                'Email Verification',
                employee?.isEmailVerified == true
                    ? 'Verified ✓'
                    : 'Not verified',
                () => AppSnackbar.info(context, employee?.isEmailVerified == true
                    ? 'Your email is verified.'
                    : 'Please verify your email from signup/login OTP flow.'),
                trailing: Icon(
                    employee?.isEmailVerified == true
                        ? Iconsax.tick_circle
                        : Iconsax.info_circle,
                    color: employee?.isEmailVerified == true
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                    size: 20)),
            const SizedBox(height: 20),
            _sectionTitle('Application'),
            _tile(
                context,
                Iconsax.info_circle,
                'About',
                'Version ${AppConstants.appVersion}',
                () => showAboutDialog(
                      context: context,
                      applicationName: AppConstants.appName,
                      applicationVersion: AppConstants.appVersion,
                      applicationIcon: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_center_rounded,
                            color: Colors.white),
                      ),
                    )),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                                  title: const Text('Logout'),
                                  content: const Text('Are you sure?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.errorColor),
                                        child: const Text('Logout'))
                                  ]));
                      if (ok == true && context.mounted) {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushReplacementNamed(LoginScreen.routeName);
                        }
                      }
                    },
                    icon:
                        const Icon(Iconsax.logout, color: AppTheme.errorColor),
                    label: const Text('Logout',
                        style: TextStyle(color: AppTheme.errorColor)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))))),
            const SizedBox(height: 40),
          ])),
    );
  }

  Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(t,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5)));

  Widget _tile(BuildContext ctx, IconData icon, String title, String sub,
      VoidCallback onTap,
      {Widget? trailing}) {
    return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: AppTheme.primaryColor, size: 20)),
                title: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: Text(sub,
                    style: const TextStyle(
                        color: AppTheme.textHint, fontSize: 12)),
                trailing: trailing ??
                    const Icon(Iconsax.arrow_right_3,
                        size: 16, color: AppTheme.textHint),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: onTap)));
  }

  void _showChangePassword(BuildContext context) {
    final currCtrl = TextEditingController(),
        newCtrl = TextEditingController(),
        confCtrl = TextEditingController();
    bool loading = false;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setMS) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    left: 24,
                    right: 24,
                    top: 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 20),
                      const Text('Change Password',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      TextFormField(
                          controller: currCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                              labelText: 'Current Password',
                              prefixIcon: const Icon(Iconsax.lock, size: 20),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: newCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: const Icon(Iconsax.lock_1, size: 20),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: confCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Iconsax.lock_1, size: 20),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 24),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: loading
                                  ? null
                                  : () async {
                                      if (newCtrl.text != confCtrl.text) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('Passwords mismatch'),
                                                backgroundColor:
                                                    AppTheme.errorColor));
                                        return;
                                      }
                                      setMS(() => loading = true);
                                      try {
                                        await _authService.changePassword(
                                            currCtrl.text, newCtrl.text);
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(const SnackBar(
                                                  content:
                                                      Text('Password changed!'),
                                                  backgroundColor:
                                                      AppTheme.successColor));
                                        }
                                      } catch (e) {
                                        setMS(() => loading = false);
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(SnackBar(
                                                  content: Text(e.toString()),
                                                  backgroundColor:
                                                      AppTheme.errorColor));
                                        }
                                      }
                                    },
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text('Change Password'))),
                      const SizedBox(height: 24),
                    ]))));
  }
}
