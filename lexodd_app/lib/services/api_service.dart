import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constant.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic data;
  final dynamic errors;

  ApiException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.data,
    this.errors,
  });

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.employeeKey);
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    return _send(() async {
      Uri uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      return http.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
    });
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    return _send(() async {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      return http
          .post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 30));
    });
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    return _send(() async {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      return http
          .put(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 30));
    });
  }

  Future<dynamic> delete(String endpoint) async {
    return _send(() async {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      return http.delete(uri, headers: _headers).timeout(const Duration(seconds: 30));
    });
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      return _handleResponse(await request());
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } catch (_) {
      throw ApiException('Network error. Check your connection.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Unexpected server response (${response.statusCode}). Please try again.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String? validationMessage;
    final errors = body is Map<String, dynamic> ? body['errors'] : null;
    if (errors is List && errors.isNotEmpty) {
      validationMessage = errors.map((error) {
        if (error is Map) {
          final field = error['field'] ?? error['path'] ?? 'field';
          final message = error['message'] ?? error['msg'] ?? 'Invalid value';
          return '$field: $message';
        }
        return error.toString();
      }).join('\n');
    }

    final message = body is Map<String, dynamic>
        ? (validationMessage ?? body['message']?.toString())
        : null;

    throw ApiException(
      message ?? 'An error occurred. Please try again.',
      statusCode: response.statusCode,
      errorCode: body is Map<String, dynamic> ? body['errorCode']?.toString() : null,
      data: body is Map<String, dynamic> ? body['data'] : null,
      errors: errors,
    );
  }
}
