import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
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

  // ===== SIGNUP =====
  Future<Employee> signup(Map<String, dynamic> data) async {
    final response = await _api.post('/auth/signup', body: data);
    
    if (response['success'] == true) {
      await _api.setToken(response['data']['token']);
      
      // Fetch full profile
      final profile = await getProfile();
      _currentEmployee = profile;
      await _saveEmployeeLocally(profile);
      return profile;
    }
    throw ApiException(response['message'] ?? 'Signup failed');
  }

  // ===== LOGIN =====
  Future<Employee> login(String email, String password) async {
    final response = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    if (response['success'] == true) {
      await _api.setToken(response['data']['token']);
      
      final profile = await getProfile();
      _currentEmployee = profile;
      await _saveEmployeeLocally(profile);
      return profile;
    }
    throw ApiException(response['message'] ?? 'Login failed');
  }

  // ===== OTP LOGIN =====
  Future<void> sendLoginOTP(String email) async {
    final response = await _api.post('/otp/send', body: {
      'email': email,
      'purpose': 'login',
    });
    if (response['success'] != true) {
      throw ApiException(response['message'] ?? 'Failed to send OTP');
    }
  }

  Future<Employee> verifyLoginOTP(String email, String otp) async {
    final response = await _api.post('/otp/verify', body: {
      'email': email,
      'otp': otp,
      'purpose': 'login',
    });

    if (response['success'] == true && response['data']['token'] != null) {
      await _api.setToken(response['data']['token']);
      
      final profile = await getProfile();
      _currentEmployee = profile;
      await _saveEmployeeLocally(profile);
      return profile;
    }
    throw ApiException(response['message'] ?? 'OTP verification failed');
  }

  // ===== EMAIL VERIFICATION =====
  Future<void> sendEmailVerificationOTP(String email) async {
    final response = await _api.post('/otp/send', body: {
      'email': email,
      'purpose': 'email_verification',
    });
    if (response['success'] != true) {
      throw ApiException(response['message'] ?? 'Failed to send OTP');
    }
  }

  Future<bool> verifyEmailOTP(String email, String otp) async {
    final response = await _api.post('/otp/verify', body: {
      'email': email,
      'otp': otp,
      'purpose': 'email_verification',
    });
    return response['success'] == true;
  }

  // ===== PASSWORD RESET =====
  Future<void> sendPasswordResetOTP(String email) async {
    final response = await _api.post('/otp/send', body: {
      'email': email,
      'purpose': 'password_reset',
    });
    if (response['success'] != true) {
      throw ApiException(response['message'] ?? 'Failed to send OTP');
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    final response = await _api.post('/auth/reset-password', body: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
    return response['success'] == true;
  }

  // ===== PROFILE =====
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

  Future<Employee> updateProfile(String id, Map<String, dynamic> data) async {
    final response = await _api.put('/employees/$id', body: data);
    if (response['success'] == true) {
      final employee = Employee.fromJson(response['data']['employee']);
      _currentEmployee = employee;
      await _saveEmployeeLocally(employee);
      return employee;
    }
    throw ApiException(response['message'] ?? 'Update failed');
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
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

  // ===== LOGOUT =====
  Future<void> logout() async {
    _currentEmployee = null;
    await _api.clearToken();
  }

  // ===== HELPERS =====
  Future<void> _saveEmployeeLocally(Employee employee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.employeeKey, jsonEncode(employee.toJson()));
  }
}
