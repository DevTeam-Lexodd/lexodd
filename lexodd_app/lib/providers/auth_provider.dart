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

  Future<bool> signup(Map<String, dynamic> data) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _employee = await _authService.signup(data);
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

  Future<bool> loginWithOTP(String email, String otp) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _employee = await _authService.verifyLoginOTP(email, otp);
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

  Future<bool> sendOTP(String email, {String purpose = 'login'}) async {
    try {
      await _authService.sendLoginOTP(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      _employee = await _authService.getProfile();
      notifyListeners();
    } catch (e) {
      // Silent fail for profile refresh
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_employee == null || _employee!.id == null) return false;
    
    try {
      _employee = await _authService.updateProfile(_employee!.id!, data);
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
    if (_state == AuthState.error) {
      _state = _employee != null ? AuthState.authenticated : AuthState.unauthenticated;
    }
    notifyListeners();
  }
}
