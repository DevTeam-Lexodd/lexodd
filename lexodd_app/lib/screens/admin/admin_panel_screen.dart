import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/employee_service.dart';
import '../../models/employee.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});
  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _service = EmployeeService();
  List<Employee> _employees = [];
  List<dynamic> _leaves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait(
          [_service.getEmployees(limit: 100), _service.getAllLeaves()]);
      if (mounted) {
        setState(() {
          final employeeResult = results[0] as Map<String, dynamic>;
          _employees = employeeResult['employees'] as List<Employee>;
          _leaves = results[1] as List<dynamic>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approveUser(Employee employee, String status) async {
    if (employee.id == null) return;
    await _service.updateEmployee(employee.id!, {'approvalStatus': status});
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Admin approvals'),
            automaticallyImplyLeading: false),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  const Text('User registration requests',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ..._employees
                      .where((e) => e.approvalStatus != 'approved')
                      .map(_userCard),
                  const SizedBox(height: 24),
                  const Text('Leave requests',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ..._leaves.map(_leaveCard),
                ]),
              ),
      );

  Widget _userCard(Employee employee) => Card(
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(employee.fullName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(employee.email),
            Text('Status: ${employee.approvalStatus}'),
            Row(children: [
              TextButton(
                  onPressed: () => _approveUser(employee, 'approved'),
                  child: const Text('Approve')),
              TextButton(
                  onPressed: () => _approveUser(employee, 'rejected'),
                  child: const Text('Reject',
                      style: TextStyle(color: AppTheme.errorColor)))
            ]),
          ])));

  Widget _leaveCard(dynamic leave) {
    final employee = leave['employee'];
    final status = leave['status'] ?? 'pending';
    return Card(
        child: ListTile(
            title: Text(
                '${employee?['firstName'] ?? 'Employee'} • ${leave['leaveType'] ?? ''}'),
            subtitle: Text('${leave['reason'] ?? ''}\n$status'),
            isThreeLine: true,
            trailing: status == 'pending'
                ? Wrap(children: [
                    IconButton(
                        icon: const Icon(Icons.check,
                            color: AppTheme.successColor),
                        onPressed: () async {
                          await _service.updateLeaveStatus(
                              leave['_id'], 'approved');
                          _load();
                        }),
                    IconButton(
                        icon:
                            const Icon(Icons.close, color: AppTheme.errorColor),
                        onPressed: () async {
                          await _service.updateLeaveStatus(
                              leave['_id'], 'rejected',
                              rejectionReason: 'Rejected by admin');
                          _load();
                        })
                  ])
                : null));
  }
}
