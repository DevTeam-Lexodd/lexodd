import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constant.dart';
import '../models/employee.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  Employee? _currentEmployee;
  Employee? get currentEmployee => _currentEmployee;
  bool get isLoggedIn => _currentEmployee != null;

  Future<void> init() async {
    await _api.init();
    final prefs = await SharedPreferences.getInstance();
    final employeeJson = prefs.getString(AppConstants.employeeKey);
    if (employeeJson != null) {
      _currentEmployee = Employee.fromJson(jsonDecode(employeeJson));
    }
  }

  // SIGNUP - POST /api/auth/signup after email OTP has been verified.
  Future<Employee> signup(Map<String, dynamic> data) async {
    final response = await _api.post('/auth/signup', body: data);
    if (response['success'] == true) {
      final token = response['data']?['token'] as String?;
      final employeeData = response['data']?['employee'];
      if (token == null || employeeData == null) {
        throw ApiException('Registration completed without account details.');
      }
      await _api.setToken(token);
      final employee = Employee.fromJson(employeeData);
      _currentEmployee = employee;
      await _saveEmployeeLocally(employee);
      return employee;
    }
    throw ApiException(response['message'] ?? 'Signup failed');
  }

  // LOGIN - POST /api/auth/login
  Future<Employee> login(String email, String password) async {
    final response = await _api
        .post('/auth/login', body: {'email': email, 'password': password});
    if (response['success'] == true) {
      await _api.setToken(response['data']['token']);
      final loginEmployee = response['data']['employee'];
      // Pending users are intentionally blocked from /me by the server, but
      // still need their approval screen after login.
      final profile = loginEmployee['approvalStatus'] == 'approved'
          ? await getProfile()
          : Employee.fromJson(loginEmployee);
      _currentEmployee = profile;
      await _saveEmployeeLocally(profile);
      return profile;
    }
    throw ApiException(response['message'] ?? 'Login failed');
  }

  // SEND OTP - POST /api/auth/send-otp (for login or password reset)
  Future<String> sendOTP(String email, {String purpose = 'login'}) async {
    final response = await _api
        .post('/auth/send-otp', body: {'email': email, 'purpose': purpose});
    if (response['success'] != true ||
        response['data']?['verificationToken'] == null) {
      throw ApiException(response['message'] ?? 'Failed to send OTP');
    }
    return response['data']['verificationToken'] as String;
  }

  // VERIFY OTP - POST /api/auth/verify-otp
  // For email_verification: creates employee, returns token + employee
  // For login: returns token + employee
  // For password_reset: returns verified: true
  Future<Map<String, dynamic>> verifyOTP(
    String email,
    String otp, {
    required String verificationToken,
    String purpose = 'email_verification',
  }) async {
    final response = await _api.post('/auth/verify-otp', body: {
      'email': email,
      'otp': otp,
      'purpose': purpose,
      'verificationToken': verificationToken,
    });
    if (response['success'] == true) {
      final data = response['data'] ?? {};

      // If token returned (signup verification or OTP login), store it and fetch profile
      if (data['token'] != null) {
        await _api.setToken(data['token']);
        final profile = await getProfile();
        _currentEmployee = profile;
        await _saveEmployeeLocally(profile);
      } else if (_currentEmployee != null) {
        // For password reset, just refresh profile
        await getProfile();
      }
      return data;
    }
    throw ApiException(response['message'] ?? 'OTP verification failed');
  }

  // RESET PASSWORD - POST /api/auth/reset-password
  Future<bool> resetPassword(
    String email,
    String otp,
    String newPassword, {
    required String verificationToken,
  }) async {
    final response = await _api.post('/auth/reset-password', body: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
      'verificationToken': verificationToken,
    });
    return response['success'] == true;
  }

  // GET PROFILE - GET /api/auth/me
  Future<Employee> getProfile() async {
    final response = await _api.get('/auth/me');
    if (response['success'] == true) {
      final employee = Employee.fromJson(response['data']['employee']);
      _currentEmployee = employee;
      await _saveEmployeeLocally(employee);
      return employee;
    }
    throw ApiException('Failed to fetch profile');
  }

  // UPDATE PROFILE - PUT /api/auth/update-profile
  Future<Employee> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.put('/auth/update-profile', body: data);
    if (response['success'] == true) {
      final employee = Employee.fromJson(response['data']['employee']);
      _currentEmployee = employee;
      await _saveEmployeeLocally(employee);
      return employee;
    }
    throw ApiException(response['message'] ?? 'Update failed');
  }

  // CHANGE PASSWORD - PUT /api/auth/change-password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final response = await _api.put('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    if (response['success'] == true) {
      if (response['data']?['token'] != null) {
        await _api.setToken(response['data']['token']);
      }
    } else {
      throw ApiException(response['message'] ?? 'Password change failed');
    }
  }

  // LOGOUT
  Future<void> logout() async {
    _currentEmployee = null;
    await _api.clearToken();
  }

  Future<void> _saveEmployeeLocally(Employee employee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.employeeKey, jsonEncode(employee.toJson()));
  }
}
