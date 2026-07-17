import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/employee.dart';
import '../providers/auth_provider.dart';
import '../services/employee_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';
  final String? employeeId;

  const ProfileScreen({super.key, this.employeeId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _employeeService = EmployeeService();
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _country = TextEditingController(text: 'India');
  final _emergencyName = TextEditingController();
  final _emergencyRelation = TextEditingController();
  final _emergencyPhone = TextEditingController();

  Employee? _employee;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _profilePhoto;

  bool get _isSelf {
    final currentId = context.read<AuthProvider>().employee?.id;
    return widget.employeeId == null || widget.employeeId == currentId;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _country.dispose();
    _emergencyName.dispose();
    _emergencyRelation.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      Employee employee;
      if (_isSelf) {
        final auth = context.read<AuthProvider>();
        final refreshed = await auth.refreshProfile();
        employee = refreshed ? auth.employee! : auth.employee!;
      } else {
        employee = await _employeeService.getEmployeeById(widget.employeeId!);
      }
      if (!mounted) return;
      setState(() {
        _employee = employee;
        _profilePhoto = employee.profilePhoto;
        _hydrate(employee);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final fallback = context.read<AuthProvider>().employee;
      setState(() {
        _employee = _isSelf ? fallback : null;
        if (fallback != null && _isSelf) _hydrate(fallback);
        _loading = false;
      });
      if (!_isSelf || fallback == null) {
        AppSnackbar.error(context, e.toString());
      }
    }
  }

  void _hydrate(Employee employee) {
    _firstName.text = employee.firstName;
    _lastName.text = employee.lastName;
    _phone.text = employee.phone;
    _street.text = employee.address?.street ?? '';
    _city.text = employee.address?.city ?? '';
    _state.text = employee.address?.state ?? '';
    _pincode.text = employee.address?.pincode ?? '';
    _country.text = employee.address?.country ?? 'India';
    _emergencyName.text = employee.emergencyContact?.name ?? '';
    _emergencyRelation.text = employee.emergencyContact?.relationship ?? '';
    _emergencyPhone.text = employee.emergencyContact?.phone ?? '';
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (bytes.length > 7 * 1024 * 1024) {
      if (mounted) AppSnackbar.error(context, 'Image is too large. Choose a smaller photo.');
      return;
    }
    final ext = picked.name.split('.').last.toLowerCase();
    final type = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpeg';
    setState(() => _profilePhoto = 'data:image/$type;base64,${base64Encode(bytes)}');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'phone': _phone.text.trim(),
      'address': {
        'street': _street.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'pincode': _pincode.text.trim(),
        'country': _country.text.trim().isEmpty ? 'India' : _country.text.trim(),
      },
      'emergencyContact': {
        'name': _emergencyName.text.trim(),
        'relationship': _emergencyRelation.text.trim(),
        'phone': _emergencyPhone.text.trim(),
      },
      if (_profilePhoto != null && _profilePhoto!.isNotEmpty) 'profilePhoto': _profilePhoto,
    };

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(payload);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      setState(() {
        _employee = auth.employee;
        _editing = false;
      });
      AppSnackbar.success(context, 'Profile updated');
    } else {
      AppSnackbar.error(context, auth.errorMessage ?? 'Profile update failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelf ? 'My Profile' : 'Employee Profile'),
        actions: [
          if (_isSelf && !_loading)
            TextButton.icon(
              onPressed: _saving ? null : () => setState(() => _editing = !_editing),
              icon: Icon(_editing ? Iconsax.close_circle : Iconsax.edit, size: 18),
              label: Text(_editing ? 'Cancel' : 'Edit'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _employee == null
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth > 720 ? 720.0 : constraints.maxWidth;
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _profileHeader(_employee!),
                                  const SizedBox(height: 20),
                                  _section('Personal Information', [
                                    _responsiveRow([
                                      CustomTextField(
                                        controller: _firstName,
                                        label: 'First name',
                                        readOnly: !_editing,
                                        validator: _requiredName,
                                      ),
                                      CustomTextField(
                                        controller: _lastName,
                                        label: 'Last name',
                                        readOnly: !_editing,
                                        validator: _requiredName,
                                      ),
                                    ]),
                                    const SizedBox(height: 14),
                                    CustomTextField(
                                      controller: _phone,
                                      label: 'Phone',
                                      readOnly: !_editing,
                                      keyboardType: TextInputType.phone,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Required';
                                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) return 'Invalid phone';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _readOnlyTile(Iconsax.sms, 'Email', _employee!.email),
                                  ]),
                                  const SizedBox(height: 16),
                                  _section('Employment', [
                                    _infoWrap(_employee!),
                                  ]),
                                  const SizedBox(height: 16),
                                  _section('Address', [
                                    CustomTextField(controller: _street, label: 'Street', readOnly: !_editing),
                                    const SizedBox(height: 14),
                                    _responsiveRow([
                                      CustomTextField(controller: _city, label: 'City', readOnly: !_editing),
                                      CustomTextField(controller: _state, label: 'State', readOnly: !_editing),
                                    ]),
                                    const SizedBox(height: 14),
                                    _responsiveRow([
                                      CustomTextField(
                                        controller: _pincode,
                                        label: 'Pincode',
                                        readOnly: !_editing,
                                        keyboardType: TextInputType.number,
                                      ),
                                      CustomTextField(controller: _country, label: 'Country', readOnly: !_editing),
                                    ]),
                                  ]),
                                  const SizedBox(height: 16),
                                  _section('Emergency Contact', [
                                    CustomTextField(controller: _emergencyName, label: 'Name', readOnly: !_editing),
                                    const SizedBox(height: 14),
                                    _responsiveRow([
                                      CustomTextField(controller: _emergencyRelation, label: 'Relationship', readOnly: !_editing),
                                      CustomTextField(controller: _emergencyPhone, label: 'Phone', readOnly: !_editing, keyboardType: TextInputType.phone),
                                    ]),
                                  ]),
                                  if (_editing) ...[
                                    const SizedBox(height: 24),
                                    CustomButton(text: 'Save Profile', isLoading: _saving, onPressed: _save),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _profileHeader(Employee employee) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: _avatarImage(_profilePhoto),
                child: _avatarImage(_profilePhoto) == null
                    ? Text(
                        employee.initials,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              if (_editing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: InkWell(
                    onTap: _pickPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Iconsax.camera, size: 16, color: AppTheme.primaryColor),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  employee.designation.isEmpty ? employee.department : '${employee.designation} • ${employee.department}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _badge(employee.employeeId ?? 'Employee', Colors.white),
                    _badge(employee.role ?? 'employee', Colors.white),
                    _badge(employee.approvalStatus, _statusColor(employee.approvalStatus)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _responsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 14),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _infoWrap(Employee employee) {
    final items = <MapEntry<IconData, String>>[
      MapEntry(Iconsax.building, employee.department),
      MapEntry(Iconsax.briefcase, employee.employmentType),
      MapEntry(Iconsax.location, employee.workLocation ?? 'Work location not set'),
      MapEntry(Iconsax.timer, employee.tenure),
      if (employee.reportingManager != null && employee.reportingManager!.isNotEmpty)
        MapEntry(Iconsax.user_octagon, 'Manager: ${employee.reportingManager}'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) => _chip(e.key, e.value)).toList(),
    );
  }

  Widget _readOnlyTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textHint),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
              Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    final light = color == Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: light ? Colors.white.withValues(alpha: 0.18) : color.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.user_remove, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Profile not found', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  ImageProvider? _avatarImage(String? dataUri) {
    final bytes = _photoBytes(dataUri);
    return bytes == null ? null : MemoryImage(bytes);
  }

  Uint8List? _photoBytes(String? dataUri) {
    if (dataUri == null || !dataUri.startsWith('data:image/')) return null;
    final comma = dataUri.indexOf(',');
    if (comma == -1) return null;
    try {
      return base64Decode(dataUri.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.warningColor;
    }
  }

  String? _requiredName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.trim().length < 2) return 'Min 2 characters';
    return null;
  }
}
