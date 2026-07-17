// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/employee_service.dart';

class LeaveScreen extends StatefulWidget {
  static const String routeName = '/leaves';
  const LeaveScreen({super.key});
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final EmployeeService _service = EmployeeService();
  List<dynamic> _leaves = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final emp = context.read<AuthProvider>().employee;
    if (emp?.id == null) return;
    try {
      final result = await _service.getLeaves(emp!.id!,
          status: _filter == 'all' ? null : _filter);
      if (mounted) {
        setState(() {
          _leaves = result['leaves'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emp = context.watch<AuthProvider>().employee;
    return Scaffold(
      appBar: AppBar(
          title: const Text('My Leaves'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
                icon: const Icon(Iconsax.add_circle,
                    color: AppTheme.primaryColor),
                onPressed: _showApplyDialog)
          ]),
      body: Column(children: [
        if (emp?.leaveBalance != null)
          Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _balanceCard('Casual', emp!.leaveBalance!.casual,
                        AppTheme.primaryColor),
                    _balanceCard(
                        'Sick', emp.leaveBalance!.sick, AppTheme.errorColor),
                    _balanceCard('Earned', emp.leaveBalance!.earned,
                        AppTheme.successColor),
                    _balanceCard('Comp Off', emp.leaveBalance!.compOff,
                        AppTheme.warningColor),
                  ])),
        SizedBox(
            height: 48,
            child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _chip('All', 'all'),
                  _chip('Pending', 'pending'),
                  _chip('Approved', 'approved'),
                  _chip('Rejected', 'rejected'),
                ])),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _leaves.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            Icon(Iconsax.calendar_1,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No leaves found',
                                style:
                                    TextStyle(color: AppTheme.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                                onPressed: _showApplyDialog,
                                icon: const Icon(Iconsax.add),
                                label: const Text('Apply Leave')),
                          ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _leaves.length,
                            itemBuilder: (context, i) =>
                                _leaveCard(_leaves[i], i)))),
      ]),
    );
  }

  Widget _balanceCard(String label, double count, Color color) {
    return Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${count.toInt()}',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: color.withValues(alpha: 0.8))),
            ]));
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            selected: selected,
            onSelected: (_) {
              setState(() => _filter = value);
              _load();
            },
            selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            checkmarkColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))));
  }

  Widget _leaveCard(dynamic leave, int index) {
    final start = DateTime.parse(leave['startDate']);
    final end = DateTime.parse(leave['endDate']);
    final status = leave['status'] ?? 'pending';
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = AppTheme.successColor;
        statusIcon = Iconsax.tick_circle;
        break;
      case 'rejected':
        statusColor = AppTheme.errorColor;
        statusIcon = Iconsax.close_circle;
        break;
      default:
        statusColor = AppTheme.warningColor;
        statusIcon = Iconsax.timer;
    }
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12))
                ])),
            const Spacer(),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text((leave['leaveType'] ?? '').toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Iconsax.calendar, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13))),
            const SizedBox(width: 8),
            Text(
                '${leave['numberOfDays']} day${leave['numberOfDays'] > 1 ? 's' : ''}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ]),
          if (leave['reason'] != null) ...[
            const SizedBox(height: 8),
            Text(leave['reason'],
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis)
          ],
        ]));
  }

  void _showApplyDialog() {
    String? leaveType;
    final reasonCtrl = TextEditingController();
    DateTime? startDate, endDate;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => StatefulBuilder(
            builder: (context, setMS) => SingleChildScrollView(
                child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
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
                      const Text('Apply Leave',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                              labelText: 'Leave Type',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          items: ['casual', 'sick', 'earned', 'compOff']
                              .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                      t[0].toUpperCase() + t.substring(1))))
                              .toList(),
                          onChanged: (v) => setMS(() => leaveType = v)),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: () async {
                                  final d = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)));
                                  if (d != null) setMS(() => startDate = d);
                                },
                                icon: const Icon(Iconsax.calendar, size: 18),
                                label: Text(startDate != null
                                    ? DateFormat('dd MMM yyyy')
                                        .format(startDate!)
                                    : 'Start Date'))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: () async {
                                  final d = await showDatePicker(
                                      context: context,
                                      initialDate: startDate ?? DateTime.now(),
                                      firstDate: startDate ?? DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)));
                                  if (d != null) setMS(() => endDate = d);
                                },
                                icon: const Icon(Iconsax.calendar, size: 18),
                                label: Text(endDate != null
                                    ? DateFormat('dd MMM yyyy').format(endDate!)
                                    : 'End Date'))),
                      ]),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: reasonCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                              labelText: 'Reason',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 24),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () async {
                                if (leaveType == null ||
                                    startDate == null ||
                                    endDate == null ||
                                    reasonCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Fill all fields'),
                                          backgroundColor:
                                              AppTheme.errorColor));
                                  return;
                                }
                                if (reasonCtrl.text.trim().length < 5) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Reason must be at least 5 characters'),
                                          backgroundColor:
                                              AppTheme.errorColor));
                                  return;
                                }
                                final empId =
                                    context.read<AuthProvider>().employee?.id;
                                if (empId == null) return;
                                try {
                                  await _service.applyLeave(empId, {
                                    'leaveType': leaveType,
                                    'startDate': startDate!.toIso8601String(),
                                    'endDate': endDate!.toIso8601String(),
                                    'reason': reasonCtrl.text.trim()
                                  });
                                  Navigator.pop(context);
                                  _load();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Leave applied!'),
                                            backgroundColor:
                                                AppTheme.successColor));
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(e.toString()),
                                          backgroundColor:
                                              AppTheme.errorColor));
                                }
                              },
                              child: const Text('Submit'))),
                      const SizedBox(height: 24),
                    ])))));
  }
}
