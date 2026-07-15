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

  // SIGNUP - POST /api/auth/signup
  Future<SignupResult> signup(Map<String, dynamic> data) async {
    final response = await _api.post('/auth/signup', body: data);
    if (response['success'] == true) {
      await _api.setToken(response['data']['token']);
      final profile = await getProfile();
      _currentEmployee = profile;
      await _saveEmployeeLocally(profile);
      final verificationToken = response['data']?['verificationToken'] as String?;
      if (verificationToken == null || verificationToken.isEmpty) {
        throw ApiException('Registration succeeded, but no verification token was returned.');
      }
      return SignupResult(employee: profile, verificationToken: verificationToken);
    }
    throw ApiException(response['message'] ?? 'Signup failed');
  }

  // LOGIN - POST /api/auth/login
  Future<Employee> login(String email, String password) async {
    final response = await _api.post('/auth/login', body: {'email': email, 'password': password});
    if (response['success'] == true) {
      await _api.setToken(response['data']['token']);
      final profile = await getProfile();
      _currentEmployee = profile;
      await _saveEmployeeLocally(profile);
      return profile;
    }
    throw ApiException(response['message'] ?? 'Login failed');
  }

  // SEND OTP - POST /api/otp/send
  Future<String> sendOTP(String email, {String purpose = 'email_verification'}) async {
    final response = await _api.post('/otp/send', body: {'email': email, 'purpose': purpose});
    if (response['success'] != true || response['data']?['verificationToken'] == null) {
      throw ApiException(response['message'] ?? 'Failed to send OTP');
    }
    return response['data']['verificationToken'] as String;
  }

  // VERIFY OTP - POST /api/otp/verify
  Future<Map<String, dynamic>> verifyOTP(String email, String otp, {
    required String verificationToken,
    String purpose = 'email_verification',
  }) async {
    final response = await _api.post('/otp/verify', body: {
      'email': email,
      'otp': otp,
      'purpose': purpose,
      'verificationToken': verificationToken,
    });
    if (response['success'] == true) {
      // Login OTP returns a fresh session token. Email verification refreshes
      // the signed-in profile so the verified state is stored locally.
      if (response['data']?['token'] != null) {
        await _api.setToken(response['data']['token']);
      }
      if (_currentEmployee != null || response['data']?['token'] != null) {
        await getProfile();
      }
      return response['data'] ?? {};
    }
    throw ApiException(response['message'] ?? 'OTP verification failed');
  }

  // RESET PASSWORD - POST /api/auth/reset-password
  Future<bool> resetPassword(String email, String otp, String newPassword, {
    required String verificationToken,
  }) async {
    final response = await _api.post('/auth/reset-password', body: {
      'email': email, 'otp': otp, 'newPassword': newPassword,
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
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await _api.put('/auth/change-password', body: {
      'currentPassword': currentPassword, 'newPassword': newPassword,
    });
    if (response['success'] == true) {
      if (response['data']?['token'] != null) await _api.setToken(response['data']['token']);
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
    await prefs.setString(AppConstants.employeeKey, jsonEncode(employee.toJson()));
  }
}

class SignupResult {
  final Employee employee;
  final String verificationToken;

  const SignupResult({required this.employee, required this.verificationToken});
}
