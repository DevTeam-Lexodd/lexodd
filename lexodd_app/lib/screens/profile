import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/employee.dart';
import '../../providers/auth_provider.dart';
import '../../services/employee_service.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';
  final String? employeeId;
  const ProfileScreen({super.key, this.employeeId});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final EmployeeService _service = EmployeeService();
  Employee? _employee;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.employeeId != null) {
        final emp = await _service.getEmployeeById(widget.employeeId!);
        setState(() {
          _employee = emp;
          _loading = false;
        });
      } else {
        setState(() {
          _employee = context.read<AuthProvider>().employee;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: const Center(child: CircularProgressIndicator()));
    }
    final emp = _employee;
    if (emp == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: const Center(child: Text('Not found')));
    }

    return Scaffold(
        body: CustomScrollView(slivers: [
      SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
              background: Container(
                  decoration:
                      const BoxDecoration(gradient: AppTheme.primaryGradient),
                  child: SafeArea(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        const SizedBox(height: 40),
                        Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 2)),
                            child: Center(
                                child: Text(emp.initials,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700)))),
                        const SizedBox(height: 12),
                        Text(emp.fullName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(emp.employeeId ?? '',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12))),
                        const SizedBox(height: 8),
                        Text('${emp.designation} • ${emp.department}',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13)),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: _quickStat('Tenure', emp.tenure)),
                          Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withValues(alpha: 0.3)),
                          Expanded(
                              child: _quickStat('Type', emp.employmentType)),
                          Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withValues(alpha: 0.3)),
                          Expanded(
                              child: _quickStat('Status',
                                  emp.isActive ? 'Active' : 'Inactive')),
                        ]),
                      ]))))),
      SliverToBoxAdapter(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _section('Personal Information', Iconsax.user, [
                  _row('Full Name', emp.fullName),
                  _row('Email', emp.email),
                  _row('Phone', emp.phone),
                  if (emp.dateOfBirth != null)
                    _row('DOB',
                        DateFormat('dd MMM yyyy').format(emp.dateOfBirth!)),
                  _row('Gender', emp.gender),
                  if (emp.bloodGroup != null && emp.bloodGroup!.isNotEmpty)
                    _row('Blood Group', emp.bloodGroup!),
                  if (emp.age != null) _row('Age', '${emp.age} years'),
                ]),
                const SizedBox(height: 16),
                if (emp.address != null)
                  _section('Address', Iconsax.home, [
                    _row('Street', emp.address!.street ?? 'N/A'),
                    _row('City', emp.address!.city ?? 'N/A'),
                    _row('State', emp.address!.state ?? 'N/A'),
                    _row('Pincode', emp.address!.pincode ?? 'N/A'),
                  ]),
                const SizedBox(height: 16),
                _section('Employment', Iconsax.briefcase, [
                  _row('Employee ID', emp.employeeId ?? 'N/A'),
                  _row('Department', emp.department),
                  _row('Designation', emp.designation),
                  _row('Employment Type', emp.employmentType),
                  if (emp.dateOfJoining != null)
                    _row('Joining Date',
                        DateFormat('dd MMM yyyy').format(emp.dateOfJoining!)),
                  _row('Work Location', emp.workLocation ?? 'N/A'),
                  _row('Tenure', emp.tenure),
                  if (emp.ctc != null)
                    _row('CTC',
                        '₹${NumberFormat('#,##,###').format(emp.ctc!.toInt())}'),
                ]),
                const SizedBox(height: 16),
                if (emp.emergencyContact != null)
                  _section('Emergency Contact', Iconsax.call_add, [
                    _row('Name', emp.emergencyContact!.name ?? 'N/A'),
                    _row('Relationship',
                        emp.emergencyContact!.relationship ?? 'N/A'),
                    _row('Phone', emp.emergencyContact!.phone ?? 'N/A'),
                  ]),
                const SizedBox(height: 16),
                if (emp.bankDetails != null)
                  _section('Bank Details', Iconsax.bank, [
                    _row('Bank', emp.bankDetails!.bankName ?? 'N/A'),
                    _row('Account', emp.bankDetails!.accountNumber ?? 'N/A'),
                    _row('IFSC', emp.bankDetails!.ifscCode ?? 'N/A'),
                  ]),
                const SizedBox(height: 16),
                if (emp.leaveBalance != null)
                  _section('Leave Balance', Iconsax.calendar, [
                    _leaveRow('Casual', emp.leaveBalance!.casual,
                        AppTheme.primaryColor),
                    _leaveRow(
                        'Sick', emp.leaveBalance!.sick, AppTheme.errorColor),
                    _leaveRow('Earned', emp.leaveBalance!.earned,
                        AppTheme.successColor),
                    _leaveRow('Comp Off', emp.leaveBalance!.compOff,
                        AppTheme.warningColor),
                  ]),
                const SizedBox(height: 40),
              ]))),
    ]));
  }

  Widget _quickStat(String label, String value) => Column(children: [
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ]);

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16))),
              child: Row(children: [
                Icon(icon, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.primaryColor))
              ])),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: children)),
        ]));
  }

  Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13))),
      ]));

  Widget _leaveRow(String label, double count, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          const gap = 2.0;
          final blockWidth = (constraints.maxWidth - gap * 14) / 15;
          return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(
                  15,
                  (i) => Container(
                      width: blockWidth,
                      height: 16,
                      margin: EdgeInsets.only(left: i == 0 ? 0 : gap),
                      decoration: BoxDecoration(
                          color: i < count ? color : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3)))));
        })),
        const SizedBox(width: 8),
        Text('${count.toInt()}',
            style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ]));
}
