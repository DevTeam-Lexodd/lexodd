import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../config/constants.dart';
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
  final EmployeeService _employeeService = EmployeeService();
  DashboardData? _dashboardData;
  bool _isLoading = true;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await _employeeService.getDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<AuthProvider>().employee;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ===== CAROUSEL SLIDER =====
            _buildCarousel().animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 24),

            // ===== QUICK ACTIONS =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 12),
            _buildQuickActions().animate(delay: 300.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ===== STATS CARDS =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Overview', style: Theme.of(context).textTheme.titleLarge),
            ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 12),
            _buildStatsGrid().animate(delay: 500.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ===== LEAVE BALANCE =====
            if (employee?.leaveBalance != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('My Leave Balance', style: Theme.of(context).textTheme.titleLarge),
              ).animate(delay: 600.ms).fadeIn(duration: 500.ms),
              const SizedBox(height: 12),
              _buildLeaveBalance(employee!.leaveBalance!).animate(delay: 700.ms).fadeIn(duration: 500.ms),
            ],

            const SizedBox(height: 24),

            // ===== RECENT JOINERS =====
            if (_dashboardData?.recentJoinees.isNotEmpty == true) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Recent Joinees', style: Theme.of(context).textTheme.titleLarge),
              ).animate(delay: 800.ms).fadeIn(duration: 500.ms),
              const SizedBox(height: 12),
              _buildRecentJoinees().animate(delay: 900.ms).fadeIn(duration: 500.ms),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: AppConstants.carouselItems.length,
          itemBuilder: (context, index, realIndex) {
            final item = AppConstants.carouselItems[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.9),
                    AppTheme.primaryDark.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    bottom: -30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '✨ Featured',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['subtitle']!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          options: CarouselOptions(
            height: 160,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: true,
            viewportFraction: 0.88,
            onPageChanged: (index, reason) {
              setState(() => _currentCarouselIndex = index);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AppConstants.carouselItems.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentCarouselIndex == entry.key ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentCarouselIndex == entry.key
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Iconsax.calendar_add, 'label': 'Apply Leave', 'color': const Color(0xFF667EEA)},
      {'icon': Iconsax.profile_2user, 'label': 'My Profile', 'color': const Color(0xFF10B981)},
      {'icon': Iconsax.document_text, 'label': 'Payslip', 'color': const Color(0xFFF59E0B)},
      {'icon': Iconsax.message_question, 'label': 'Support', 'color': const Color(0xFF8B5CF6)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((action) {
          return GestureDetector(
            onTap: () {},
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  action['label'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          StatCard(
            icon: Iconsax.people,
            title: 'Total Employees',
            value: '${_dashboardData?.totalEmployees ?? 0}',
            color: AppTheme.primaryColor,
          ),
          StatCard(
            icon: Iconsax.calendar_tick,
            title: 'On Leave Today',
            value: '${_dashboardData?.todayLeaves ?? 0}',
            color: AppTheme.warningColor,
          ),
          StatCard(
            icon: Iconsax.timer_1,
            title: 'Pending Leaves',
            value: '${_dashboardData?.pendingLeaves ?? 0}',
            color: AppTheme.infoColor,
          ),
          StatCard(
            icon: Iconsax.building,
            title: 'Departments',
            value: '${_dashboardData?.departmentStats.length ?? 0}',
            color: AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalance(dynamic balance) {
    final leaves = [
      {'name': 'Casual', 'count': balance.casual, 'color': const Color(0xFF667EEA)},
      {'name': 'Sick', 'count': balance.sick, 'color': const Color(0xFFEF4444)},
      {'name': 'Earned', 'count': balance.earned, 'color': const Color(0xFF10B981)},
      {'name': 'Comp Off', 'count': balance.compOff, 'color': const Color(0xFFF59E0B)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: leaves.map((leave) {
                return Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (leave['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${leave['count']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: leave['color'] as Color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      leave['name'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentJoinees() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _dashboardData!.recentJoinees.length,
          separatorBuilder: (_, _) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final emp = _dashboardData!.recentJoinees[index];
            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    emp.initials,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${emp.designation} • ${emp.department}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  emp.dateOfJoining != null
                      ? '${emp.dateOfJoining!.day}/${emp.dateOfJoining!.month}/${emp.dateOfJoining!.year}'
                      : '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
