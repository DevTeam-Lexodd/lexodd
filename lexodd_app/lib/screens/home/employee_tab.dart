import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/employee.dart';
import '../../services/employee_service.dart';
import '../profile/profile_screen.dart';

class EmployeesTab extends StatefulWidget {
  const EmployeesTab({super.key});
  @override
  State<EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<EmployeesTab> {
  final EmployeeService _service = EmployeeService();
  final _searchController = TextEditingController();
  List<Employee> _employees = [];
  bool _loading = true;
  String? _selectedDept;
  int _total = 0;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load({bool refresh = false}) async {
    try {
      final result = await _service.getEmployees(search: _searchController.text.isNotEmpty ? _searchController.text : null, department: _selectedDept);
      if (mounted) setState(() { _employees = result['employees']; _total = result['pagination']['total']; _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Team ($_total)'), automaticallyImplyLeading: false),
      body: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
          TextFormField(controller: _searchController, decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
            suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchController.clear(); _load(refresh: true); }) : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            onFieldSubmitted: (_) => _load(refresh: true)),
          const SizedBox(height: 12),
          SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: [
            _filterChip('All', null), ...['Engineering', 'Human Resources', 'Finance', 'Marketing', 'Sales', 'IT'].map((d) => _filterChip(d, d)),
          ])),
        ])),
        const SizedBox(height: 12),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _employees.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.people, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('No employees found', style: TextStyle(color: AppTheme.textSecondary))]))
          : RefreshIndicator(onRefresh: () => _load(refresh: true), child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _employees.length,
            itemBuilder: (context, i) => _employeeCard(_employees[i], i)))),
      ]),
    );
  }

  Widget _filterChip(String label, String? dept) {
    final selected = _selectedDept == dept;
    return Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(label, style: const TextStyle(fontSize: 12)), selected: selected,
      onSelected: (_) { setState(() => _selectedDept = dept); _load(refresh: true); },
      selectedColor: AppTheme.primaryColor.withOpacity(0.15), checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(color: selected ? AppTheme.primaryColor : AppTheme.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selected ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey.shade300))));
  }

  Widget _employeeCard(Employee emp, int index) {
    return GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(employeeId: emp.id))),
      child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.8), AppTheme.primaryDark.withOpacity(0.8)]), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(emp.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(emp.employeeId ?? '', style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 4),
            Text(emp.designation, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Row(children: [
              _tag(emp.department, AppTheme.infoColor), const SizedBox(width: 6), _tag(emp.employmentType, AppTheme.successColor),
            ]),
          ])),
          Icon(Iconsax.arrow_right_3, size: 18, color: AppTheme.textHint),
        ])));
  }

  Widget _tag(String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)));
  }
}
