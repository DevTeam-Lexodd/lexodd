import '../models/employee.dart';
import 'api_service.dart';

class DashboardData {
  final int totalEmployees;
  final List<DepartmentStat> departmentStats;
  final int pendingLeaves;
  final List<Employee> recentJoinees;

  DashboardData(
      {required this.totalEmployees,
      required this.departmentStats,
      required this.pendingLeaves,
      required this.recentJoinees});

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalEmployees: json['totalEmployees'] ?? 0,
      departmentStats: (json['departmentStats'] as List?)
              ?.map((e) => DepartmentStat.fromJson(e))
              .toList() ??
          [],
      pendingLeaves: json['pendingLeaves'] ?? 0,
      recentJoinees: (json['recentJoinees'] as List?)
              ?.map((e) => Employee.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DepartmentStat {
  final String department;
  final int count;
  DepartmentStat({required this.department, required this.count});
  factory DepartmentStat.fromJson(Map<String, dynamic> json) {
    return DepartmentStat(
        department: json['_id'] ?? '', count: json['count'] ?? 0);
  }
}

class EmployeeService {
  final ApiService _api = ApiService();

  // GET /api/employees
  Future<Map<String, dynamic>> getEmployees(
      {int page = 1,
      int limit = 20,
      String? search,
      String? department}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString()
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (department != null && department.isNotEmpty) {
      queryParams['department'] = department;
    }

    final response = await _api.get('/employees', queryParams: queryParams);
    if (response['success'] == true) {
      final employees =
          (response['data'] as List).map((e) => Employee.fromJson(e)).toList();
      return {'employees': employees, 'pagination': response['pagination']};
    }
    throw ApiException('Failed to fetch employees');
  }

  // GET /api/employees/dashboard
  Future<DashboardData> getDashboard() async {
    final response = await _api.get('/employees/dashboard');
    if (response['success'] == true) {
      return DashboardData.fromJson(response['data']);
    }
    throw ApiException('Failed to fetch dashboard');
  }

  // GET /api/employees/:id
  Future<Employee> getEmployeeById(String id) async {
    final response = await _api.get('/employees/$id');
    if (response['success'] == true) {
      return Employee.fromJson(response['data']['employee']);
    }
    throw ApiException('Failed to fetch employee');
  }

  // PUT /api/employees/:id
  Future<Employee> updateEmployee(String id, Map<String, dynamic> data) async {
    final response = await _api.put('/employees/$id', body: data);
    if (response['success'] == true) {
      return Employee.fromJson(response['data']['employee']);
    }
    throw ApiException(response['message'] ?? 'Update failed');
  }

  // GET /api/employees/:id/leaves
  Future<Map<String, dynamic>> getLeaves(String employeeId,
      {int page = 1, int limit = 20, String? status}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString()
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    final response = await _api.get('/employees/$employeeId/leaves',
        queryParams: queryParams);
    if (response['success'] == true) return response['data'];
    throw ApiException('Failed to fetch leaves');
  }

  // POST /api/employees/:id/leaves
  Future<void> applyLeave(String employeeId, Map<String, dynamic> data) async {
    final response =
        await _api.post('/employees/$employeeId/leaves', body: data);
    if (response['success'] != true) {
      throw ApiException(response['message'] ?? 'Failed to apply leave');
    }
  }

  // PUT /api/employees/leaves/:leaveId/approve
  Future<void> updateLeaveStatus(String leaveId, String status,
      {String? rejectionReason}) async {
    final body = <String, dynamic>{'status': status};
    if (rejectionReason != null) body['rejectionReason'] = rejectionReason;
    final response =
        await _api.put('/employees/leaves/$leaveId/approve', body: body);
    if (response['success'] != true) {
      throw ApiException(response['message'] ?? 'Failed to update leave');
    }
  }

  Future<List<dynamic>> getAllLeaves() async {
    final response = await _api.get('/employees/leaves');
    if (response['success'] == true) {
      return response['data']['leaves'] as List<dynamic>;
    }
    throw ApiException('Failed to fetch leaves');
  }
}
