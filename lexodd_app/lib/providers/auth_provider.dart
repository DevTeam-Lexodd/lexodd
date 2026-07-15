import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/auth_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  Employee? _employee;
  String? _errorMessage;

  AuthState get state => _state;
  Employee? get employee => _employee;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  Future<void> init() async {
    await _authService.init();
    if (_authService.currentEmployee != null) {
      _employee = _authService.currentEmployee;
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<String?> signup(Map<String, dynamic> data) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.signup(data);
      _employee = result.employee;
      _state = AuthState.authenticated;
      notifyListeners();
      return result.verificationToken;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _employee = await _authService.login(email, password);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithOTP(String email, String otp, {required String verificationToken}) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.verifyOTP(email, otp,
          purpose: 'login', verificationToken: verificationToken);
      _employee = _authService.currentEmployee;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<String?> sendOTP(String email, {String purpose = 'email_verification'}) async {
    try {
      return await _authService.sendOTP(email, purpose: purpose);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyOTP(String email, String otp, {
    required String verificationToken,
    String purpose = 'email_verification',
  }) async {
    try {
      await _authService.verifyOTP(email, otp,
          purpose: purpose, verificationToken: verificationToken);
      _employee = _authService.currentEmployee;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword, {
    required String verificationToken,
  }) async {
    try {
      return await _authService.resetPassword(email, otp, newPassword,
          verificationToken: verificationToken);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      _employee = await _authService.updateProfile(data);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _employee = null;
    _state = AuthState.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
