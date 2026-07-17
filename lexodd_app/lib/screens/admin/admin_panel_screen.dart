import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/employee.dart';
import '../../services/employee_service.dart';
import '../../utils/app_snackbar.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final _service = EmployeeService();
  late final TabController _tabController;

  List<Employee> _pendingRegistrations = [];
  List<Employee> _employees = [];
  List<dynamic> _leaves = [];
  bool _loading = true;
  String? _error;
  String _leaveFilter = 'pending';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _service.getPendingApprovals(),
        _service.getAllLeaves(status: _leaveFilter),
        _service.getEmployees(limit: 100, search: _search.isEmpty ? null : _search),
      ]);
      if (!mounted) return;
      final employeeResult = results[2] as Map<String, dynamic>;
      setState(() {
        _pendingRegistrations = results[0] as List<Employee>;
        _leaves = results[1] as List<dynamic>;
        _employees = employeeResult['employees'] as List<Employee>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      AppSnackbar.error(context, e.toString());
    }
  }

  Future<void> _updateApproval(Employee employee, String status) async {
    if (employee.id == null) return;
    String? reason;
    if (status == 'rejected') {
      reason = await _askReason('Reject Registration', 'Reason for rejecting ${employee.fullName}');
      if (reason == null) return;
    } else {
      final ok = await _confirm('Approve Registration', 'Allow ${employee.fullName} to access the application?');
      if (ok != true) return;
    }

    try {
      await _service.updateApproval(employee.id!, status, rejectionReason: reason);
      if (!mounted) return;
      AppSnackbar.success(context, 'Registration $status');
      await _load();
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    }
  }

  Future<void> _updateLeave(dynamic leave, String status) async {
    final id = leave['_id']?.toString();
    if (id == null) return;
    String? reason;
    if (status == 'rejected') {
      reason = await _askReason('Reject Leave', 'Reason for rejecting this leave request');
      if (reason == null) return;
    } else {
      final ok = await _confirm('Approve Leave', 'Approve this leave request?');
      if (ok != true) return;
    }

    try {
      await _service.updateLeaveStatus(id, status, rejectionReason: reason);
      if (!mounted) return;
      AppSnackbar.success(context, 'Leave $status');
      await _load();
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    }
  }

  Future<void> _changeRole(Employee employee, String role) async {
    if (employee.id == null || employee.role == role) return;
    final ok = await _confirm(
      'Change Role',
      'Change ${employee.fullName} from ${employee.role ?? 'employee'} to $role? This takes effect after their next refresh/login.',
    );
    if (ok != true) return;
    try {
      await _service.updateRole(employee.id!, role);
      if (!mounted) return;
      AppSnackbar.success(context, 'Role updated to $role');
      await _load();
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    }
  }

  Future<void> _deactivate(Employee employee) async {
    if (employee.id == null) return;
    final ok = await _confirm('Deactivate Employee', 'Deactivate ${employee.fullName}? They will no longer be able to login.');
    if (ok != true) return;
    try {
      await _service.deactivateEmployee(employee.id!);
      if (!mounted) return;
      AppSnackbar.success(context, 'Employee deactivated');
      await _load();
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(text: 'Registrations (${_pendingRegistrations.length})'),
            Tab(text: 'Leaves (${_leaves.length})'),
            Tab(text: 'Team & Roles (${_employees.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _registrationsTab(),
                    _leavesTab(),
                    _teamTab(),
                  ],
                ),
    );
  }

  Widget _registrationsTab() {
    if (_pendingRegistrations.isEmpty) {
      return _emptyState(Iconsax.tick_circle, 'No pending approvals', 'New employee registrations will appear here.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRegistrations.length,
        itemBuilder: (context, index) => _registrationCard(_pendingRegistrations[index]),
      ),
    );
  }

  Widget _registrationCard(Employee employee) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(employee),
              const SizedBox(width: 12),
              Expanded(child: _employeeHeadline(employee)),
              _statusChip(employee.approvalStatus),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniInfo(Iconsax.sms, employee.email),
              _miniInfo(Iconsax.call, employee.phone),
              _miniInfo(Iconsax.briefcase, employee.employmentType),
              if (employee.dateOfJoining != null)
                _miniInfo(Iconsax.calendar, DateFormat('dd MMM yyyy').format(employee.dateOfJoining!)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _updateApproval(employee, 'rejected'),
                icon: const Icon(Iconsax.close_circle, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor),
              ),
              ElevatedButton.icon(
                onPressed: () => _updateApproval(employee, 'approved'),
                icon: const Icon(Iconsax.tick_circle, size: 18),
                label: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leavesTab() {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: ['pending', 'approved', 'rejected', 'cancelled', 'all']
                .map((status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_title(status)),
                        selected: _leaveFilter == status,
                        onSelected: (_) {
                          setState(() => _leaveFilter = status);
                          _load();
                        },
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: _leaves.isEmpty
              ? _emptyState(Iconsax.calendar_remove, 'No leave requests', 'No leaves match the selected filter.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaves.length,
                    itemBuilder: (context, index) => _leaveCard(_leaves[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _leaveCard(dynamic leave) {
    final employee = leave['employee'];
    final status = leave['status']?.toString() ?? 'pending';
    final start = DateTime.tryParse(leave['startDate']?.toString() ?? '');
    final end = DateTime.tryParse(leave['endDate']?.toString() ?? '');
    final employeeName = employee is Map
        ? '${employee['firstName'] ?? 'Employee'} ${employee['lastName'] ?? ''}'.trim()
        : 'Employee';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$employeeName • ${_title(leave['leaveType']?.toString() ?? 'leave')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          if (start != null && end != null)
            _miniInfo(Iconsax.calendar, '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}'),
          const SizedBox(height: 8),
          Text(
            leave['reason']?.toString() ?? 'No reason provided',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          if (leave['numberOfDays'] != null) ...[
            const SizedBox(height: 8),
            _miniInfo(Iconsax.timer, '${leave['numberOfDays']} day(s)'),
          ],
          if (leave['rejectionReason'] != null) ...[
            const SizedBox(height: 8),
            Text('Reason: ${leave['rejectionReason']}', style: const TextStyle(color: AppTheme.errorColor, fontSize: 12)),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _updateLeave(leave, 'rejected'),
                  icon: const Icon(Iconsax.close_circle, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor),
                ),
                ElevatedButton.icon(
                  onPressed: () => _updateLeave(leave, 'approved'),
                  icon: const Icon(Iconsax.tick_circle, size: 18),
                  label: const Text('Approve'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search employees...',
              prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (value) {
              _search = value.trim();
              _load();
            },
          ),
        ),
        Expanded(
          child: _employees.isEmpty
              ? _emptyState(Iconsax.people, 'No employees found', 'Try a different search.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _employees.length,
                    itemBuilder: (context, index) => _teamCard(_employees[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _teamCard(Employee employee) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(employee),
              const SizedBox(width: 12),
              Expanded(child: _employeeHeadline(employee)),
              _statusChip(employee.approvalStatus),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final roleDropdown = DropdownButtonFormField<String>(
                initialValue: employee.role ?? 'employee',
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Role access',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const ['employee', 'manager', 'hr', 'admin']
                    .map((role) => DropdownMenuItem(value: role, child: Text(_title(role))))
                    .toList(),
                onChanged: (role) {
                  if (role != null) _changeRole(employee, role);
                },
              );
              final deactivateButton = OutlinedButton.icon(
                onPressed: employee.isActive ? () => _deactivate(employee) : null,
                icon: const Icon(Iconsax.user_remove, size: 18),
                label: Text(employee.isActive ? 'Deactivate' : 'Inactive'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor),
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [roleDropdown, const SizedBox(height: 10), deactivateButton],
                );
              }
              return Row(children: [Expanded(child: roleDropdown), const SizedBox(width: 12), deactivateButton]);
            },
          ),
        ],
      ),
    );
  }

  Widget _employeeHeadline(Employee employee) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(employee.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 3),
        Text(employee.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 3),
        Text('${employee.designation} • ${employee.department}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
      ],
    );
  }

  Widget _avatar(Employee employee) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Text(employee.initials, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
    );
  }

  Widget _statusChip(String status) {
    final color = switch (status) {
      'approved' => AppTheme.successColor,
      'rejected' => AppTheme.errorColor,
      _ => AppTheme.warningColor,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(_title(status), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _miniInfo(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textHint),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, size: 64, color: AppTheme.warningColor),
            const SizedBox(height: 16),
            const Text('Could not load admin data', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Future<String?> _askReason(String title, String label) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx, reason);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
  }

  String _title(String value) {
    if (value.isEmpty) return value;
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
