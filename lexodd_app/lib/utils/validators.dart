/// Central validation rules for the auth flow.
///
/// Every rule mirrors the server-side checks (hrms_backend/middleware/validate.js
/// and hrms_backend/models/Employee.js) so bad input fails instantly on the
/// device instead of after a network round-trip - which, during signup, would
/// otherwise surface only after the user has filled in five pages of forms.
class AppValidators {
  const AppValidators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');
  static final RegExp _indianMobileRegex = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
  static final RegExp _pincodeRegex = RegExp(r'^\d{6}$');
  static final RegExp _passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)');
  static final RegExp _aadharRegex = RegExp(r'^\d{12}$');
  static final RegExp _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final RegExp _ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  static bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  // Backend: required, valid email (validateSignup / validateLogin / validateEmail)
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (!isValidEmail(v)) return 'Invalid email';
    return null;
  }

  // Backend: 2-50 chars, letters/spaces/'/- only
  static String? personName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (v.length < 2) return 'Min 2 characters';
    if (v.length > 50) return 'Max 50 characters';
    if (!_nameRegex.hasMatch(v)) return 'Letters only';
    return null;
  }

  // Backend: Indian mobile numbers only
  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (!_indianMobileRegex.hasMatch(v)) return 'Invalid mobile number';
    return null;
  }

  // Backend: 6-digit Indian pincode
  static String? pincode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (!_pincodeRegex.hasMatch(v)) return 'Invalid pincode';
    return null;
  }

  // Backend: min 8 chars with uppercase, lowercase and a number
  static bool isStrongPassword(String value) =>
      value.length >= 8 && _passwordRegex.hasMatch(value);

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Required';
    if (v.length < 8) return 'Min 8 chars';
    if (!_passwordRegex.hasMatch(v)) return 'Need upper, lower & digit';
    return null;
  }

  /// Runs [check] only when the user actually typed something - for optional
  /// fields that must still be well-formed when present.
  static String? optional(String? value, String? Function(String) check) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return check(v);
  }

  static String? aadhar(String? value) => optional(
      value, (v) => _aadharRegex.hasMatch(v) ? null : 'Must be 12 digits');

  static String? pan(String? value) => optional(value,
      (v) => _panRegex.hasMatch(v.toUpperCase()) ? null : 'Format: ABCDE1234F');

  static String? ifsc(String? value) => optional(
      value,
      (v) =>
          _ifscRegex.hasMatch(v.toUpperCase()) ? null : 'Format: SBIN0001234');

  static String? amount(String? value) => optional(value, (v) {
        final parsed = double.tryParse(v);
        if (parsed == null) return 'Numbers only';
        if (parsed < 0) return 'Cannot be negative';
        return null;
      });
}
