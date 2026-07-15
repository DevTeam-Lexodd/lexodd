// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/constant.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../leaves/leave_screen.dart';
import '../../screens/settings/settings_screen.dart';
import 'dashboard_tab.dart';
import '../../screens/home/employee_tab.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _tabs = [
    const DashboardTab(),
    const EmployeesTab(),
    const LeaveScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<AuthProvider>().employee;
    return Scaffold(
      key: _scaffoldKey,
      appBar: _currentIndex == 0 ? _buildAppBar(employee) : null,
      drawer: _buildDrawer(context, employee),
      body: _tabs[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(dynamic employee) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
          icon: const Icon(Iconsax.menu_1, size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer()),
      title: Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.business_center_rounded,
                size: 20, color: Colors.white)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(AppConstants.appName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (employee != null)
            Text('Hello, ${employee.firstName}!',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      ]),
      actions: [
        IconButton(
            icon: const Icon(Iconsax.notification, size: 22), onPressed: () {}),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(employee?.initials ?? 'U',
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)))),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic employee) {
    return Drawer(
        child: Column(children: [
      Container(
          width: double.infinity,
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20),
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 2)),
                child: Center(
                    child: Text(employee?.initials ?? 'U',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)))),
            const SizedBox(height: 12),
            Text(employee?.fullName ?? 'User',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(employee?.designation ?? '',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
            const SizedBox(height: 4),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(employee?.employeeId ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500))),
          ])),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
            _drawerItem(Iconsax.home_1, 'Home', 0),
            _drawerItem(Iconsax.people, 'Employees', 1),
            _drawerItem(Iconsax.calendar, 'Leaves', 2),
            _drawerItem(Iconsax.setting_2, 'Settings', 3),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Divider()),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text('MY INFO',
                    style: TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1))),
            if (employee != null) ...[
              _infoTile(Iconsax.sms, 'Email', employee.email),
              _infoTile(Iconsax.call, 'Phone', employee.phone),
              _infoTile(Iconsax.building, 'Department', employee.department),
              _infoTile(Iconsax.briefcase, 'Type', employee.employmentType),
              _infoTile(
                  Iconsax.calendar_1,
                  'Joined',
                  employee.dateOfJoining != null
                      ? '${employee.dateOfJoining!.day}/${employee.dateOfJoining!.month}/${employee.dateOfJoining!.year}'
                      : 'N/A'),
              _infoTile(Iconsax.timer, 'Tenure', employee.tenure),
              if (employee.workLocation != null)
                _infoTile(Iconsax.location, 'Location', employee.workLocation!),
            ],
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Divider()),
            _drawerItem(Iconsax.profile_circle, 'My Profile', -1, onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
          ])),
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: ListTile(
            leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Iconsax.logout,
                    color: AppTheme.errorColor, size: 20)),
            title: const Text('Logout',
                style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context)
                    .pushReplacementNamed(LoginScreen.routeName);
              }
            },
          )),
    ]));
  }

  Widget _drawerItem(IconData icon, String title, int index,
      {VoidCallback? onTap}) {
    final active = index == _currentIndex;
    return ListTile(
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: active
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon,
              color: active ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 20)),
      title: Text(title,
          style: TextStyle(
              color: active ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selected: active,
      selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap ??
          () {
            Navigator.pop(context);
            if (index >= 0) setState(() => _currentIndex = index);
          },
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: AppTheme.textHint),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textHint)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ])),
        ]));
  }

  Widget _buildBottomNav() {
    return Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ]),
        child: SafeArea(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(0, Iconsax.home_1, 'Home'),
                      _navItem(1, Iconsax.people, 'Team'),
                      _navItem(2, Iconsax.calendar, 'Leaves'),
                      _navItem(3, Iconsax.setting_2, 'Settings'),
                    ]))));
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = index == _currentIndex;
    return GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: active
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(icon,
                  color: active ? AppTheme.primaryColor : AppTheme.textHint,
                  size: 22),
              if (active) ...[
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13))
              ],
            ])));
  }
}
