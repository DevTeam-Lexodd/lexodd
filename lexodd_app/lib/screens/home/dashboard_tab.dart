// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../config/constant.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/employee_service.dart';
import '../../widgets/stat_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final EmployeeService _service = EmployeeService();
  DashboardData? _data;
  bool _loading = true;
  int _carouselIndex = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await _service.getDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<AuthProvider>().employee;
    return RefreshIndicator(onRefresh: _load, color: AppTheme.primaryColor,
      child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        // Carousel
        _buildCarousel(),
        const SizedBox(height: 24),
        // Quick Actions
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
        const SizedBox(height: 12),
        _buildQuickActions(),
        const SizedBox(height: 24),
        // Stats
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
        const SizedBox(height: 12),
        _buildStats(),
        const SizedBox(height: 24),
        // Leave Balance
        if (employee?.leaveBalance != null) ...[
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('My Leave Balance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
          const SizedBox(height: 12),
          _buildLeaveBalance(employee!.leaveBalance!),
        ],
        const SizedBox(height: 24),
        // Recent Joinees
        if (_data?.recentJoinees.isNotEmpty == true) ...[
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Recent Joinees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
          const SizedBox(height: 12),
          _buildRecentJoinees(),
        ],
        const SizedBox(height: 20),
      ])),
    );
  }

  Widget _buildCarousel() {
    return Column(children: [
      CarouselSlider.builder(itemCount: AppConstants.carouselItems.length,
        itemBuilder: (context, index, _) {
          final item = AppConstants.carouselItems[index];
          return Container(margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.9), AppTheme.primaryDark.withOpacity(0.9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
            child: Stack(children: [
              Positioned(right: -20, top: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))),
              Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('✨ Featured', style: TextStyle(color: Colors.white, fontSize: 11))),
                const SizedBox(height: 12),
                Text(item['title']!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(item['subtitle']!, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
              ])),
            ]));
        },
        options: CarouselOptions(height: 160, autoPlay: true, autoPlayInterval: const Duration(seconds: 4), enlargeCenterPage: true, viewportFraction: 0.88,
          onPageChanged: (i, _) => setState(() => _carouselIndex = i))),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: AppConstants.carouselItems.asMap().entries.map((e) =>
        AnimatedContainer(duration: const Duration(milliseconds: 300), width: _carouselIndex == e.key ? 24 : 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: _carouselIndex == e.key ? AppTheme.primaryColor : Colors.grey.shade300))
      ).toList()),
    ]);
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Iconsax.calendar_add, 'label': 'Apply Leave', 'color': const Color(0xFF667EEA)},
      {'icon': Iconsax.profile_2user, 'label': 'My Profile', 'color': const Color(0xFF10B981)},
      {'icon': Iconsax.document_text, 'label': 'Payslip', 'color': const Color(0xFFF59E0B)},
      {'icon': Iconsax.message_question, 'label': 'Support', 'color': const Color(0xFF8B5CF6)},
    ];
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) => Column(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: (a['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 24)),
        const SizedBox(height: 8), Text(a['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
      ])).toList()));
  }

  Widget _buildStats() {
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5, children: [
        StatCard(icon: Iconsax.people, title: 'Total Employees', value: '${_data?.totalEmployees ?? 0}', color: AppTheme.primaryColor),
        StatCard(icon: Iconsax.timer_1, title: 'Pending Leaves', value: '${_data?.pendingLeaves ?? 0}', color: AppTheme.warningColor),
        StatCard(icon: Iconsax.building, title: 'Departments', value: '${_data?.departmentStats.length ?? 0}', color: AppTheme.successColor),
        StatCard(icon: Iconsax.calendar_tick, title: 'Recent Joinees', value: '${_data?.recentJoinees.length ?? 0}', color: AppTheme.infoColor),
      ]));
  }

  Widget _buildLeaveBalance(dynamic balance) {
    final leaves = [
      {'name': 'Casual', 'count': balance.casual, 'color': const Color(0xFF667EEA)},
      {'name': 'Sick', 'count': balance.sick, 'color': const Color(0xFFEF4444)},
      {'name': 'Earned', 'count': balance.earned, 'color': const Color(0xFF10B981)},
      {'name': 'Comp Off', 'count': balance.compOff, 'color': const Color(0xFFF59E0B)},
    ];
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: leaves.map((l) => Column(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: (l['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text('${l['count']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: l['color'] as Color)))),
        const SizedBox(height: 6), Text(l['name'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ])).toList())));
  }

  Widget _buildRecentJoinees() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(16),
        itemCount: _data!.recentJoinees.length, separatorBuilder: (_, __) => const Divider(height: 16),
        itemBuilder: (context, i) {
          final emp = _data!.recentJoinees[i];
          return Row(children: [
            CircleAvatar(radius: 20, backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(emp.initials, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 13))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${emp.designation} • ${emp.department}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ])),
            Text(emp.dateOfJoining != null ? '${emp.dateOfJoining!.day}/${emp.dateOfJoining!.month}/${emp.dateOfJoining!.year}' : '', style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
          ]);
        }),
    ));
  }
}
