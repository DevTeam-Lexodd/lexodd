import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    final employee = context.read<AuthProvider>().employee;
    if (employee?.id == null) return;

    try {
      final result = await _service.getLeaves(
        employee!.id!,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      if (mounted) {
        setState(() {
          _leaves = result['leaves'] ?? [];
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leaves'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_circle, color: AppTheme.primaryColor),
            onPressed: () => _showApplyLeaveDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Leave Balance Cards
          if (employee?.leaveBalance != null)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildBalanceCard('Casual', employee!.leaveBalance!.casual, AppTheme.primaryColor),
                  _buildBalanceCard('Sick', employee.leaveBalance!.sick, AppTheme.errorColor),
                  _buildBalanceCard('Earned', employee.leaveBalance!.earned, AppTheme.successColor),
                  _buildBalanceCard('Comp Off', employee.leaveBalance!.compOff, AppTheme.warningColor),
                ],
              ),
            ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Pending', 'pending'),
                _buildFilterChip('Approved', 'approved'),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),

          // Leave List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _leaves.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.calendar_1, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('No leave records found', style: TextStyle(color: AppTheme.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showApplyLeaveDialog(),
                              icon: const Icon(Iconsax.add),
                              label: const Text('Apply Leave'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLeaves,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _leaves.length,
                          itemBuilder: (context, index) {
                            return _buildLeaveCard(_leaves[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String label, double count, Color color) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${count.toInt()}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedFilter = value);
          _loadLeaves();
        },
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        checkmarkColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildLeaveCard(dynamic leave, int index) {
    final startDate = DateTime.parse(leave['startDate']);
    final endDate = DateTime.parse(leave['endDate']);
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  leave['leaveType']?.toUpperCase() ?? '',
                  style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Iconsax.calendar, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${leave['numberOfDays']} day${leave['numberOfDays'] > 1 ? 's' : ''}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          if (leave['reason'] != null) ...[
            const SizedBox(height: 8),
            Text(
              leave['reason'],
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 80)).fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  void _showApplyLeaveDialog() {
    String? leaveType;
    final reasonController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Apply Leave', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),

                  // Leave Type
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Leave Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['casual', 'sick', 'earned', 'compOff'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type[0].toUpperCase() + type.substring(1)));
                    }).toList(),
                    onChanged: (v) => setModalState(() => leaveType = v),
                  ),
                  const SizedBox(height: 16),

                  // Date Range
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setModalState(() => startDate = date);
                          },
                          icon: const Icon(Iconsax.calendar, size: 18),
                          label: Text(
                            startDate != null ? DateFormat('dd MMM yyyy').format(startDate!) : 'Start Date',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setModalState(() => endDate = date);
                          },
                          icon: const Icon(Iconsax.calendar, size: 18),
                          label: Text(
                            endDate != null ? DateFormat('dd MMM yyyy').format(endDate!) : 'End Date',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reason
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Enter reason for leave',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (leaveType == null || startDate == null || endDate == null || reasonController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppTheme.errorColor),
                          );
                          return;
                        }

                        final employee = context.read<AuthProvider>().employee;
                        if (employee?.id == null) return;

                        try {
                          await _service.applyLeave(employee!.id!, {
                            'leaveType': leaveType,
                            'startDate': startDate!.toIso8601String(),
                            'endDate': endDate!.toIso8601String(),
                            'reason': reasonController.text,
                          });
                          
                          Navigator.pop(context);
                          _loadLeaves();
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Leave applied successfully!'), backgroundColor: AppTheme.successColor),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
                          );
                        }
                      },
                      child: const Text('Submit Application'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
