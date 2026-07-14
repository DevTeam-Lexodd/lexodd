import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/home_screen.dart';

class SignupScreen extends StatefulWidget {
  static const String routeName = '/signup';
  
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  // ===== PAGE 1: Personal Information =====
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedMaritalStatus;

  // ===== PAGE 2: Address =====
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  bool _sameAsPermanent = false;
  final _pStreetController = TextEditingController();
  final _pCityController = TextEditingController();
  final _pStateController = TextEditingController();
  final _pPincodeController = TextEditingController();
  final _pCountryController = TextEditingController(text: 'India');

  // ===== PAGE 3: Employment =====
  String? _selectedDepartment;
  final _designationController = TextEditingController();
  final _joiningDateController = TextEditingController();
  String? _selectedEmploymentType;
  String? _selectedWorkLocation;
  final _reportingManagerController = TextEditingController();
  final _ctcController = TextEditingController();

  // ===== PAGE 4: Emergency & Bank =====
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _ifscController = TextEditingController();
  String? _selectedAccountType;

  // ===== PAGE 5: Documents & Password =====
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  final _passportController = TextEditingController();
  final _dlController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _dobController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _pStreetController.dispose();
    _pCityController.dispose();
    _pStateController.dispose();
    _pPincodeController.dispose();
    _pCountryController.dispose();
    _designationController.dispose();
    _joiningDateController.dispose();
    _reportingManagerController.dispose();
    _ctcController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _ifscController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _passportController.dispose();
    _dlController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_formKeys[_currentPage].currentState!.validate()) {
      if (_currentPage < _totalPages - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKeys[_currentPage].currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    final data = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      if (_altPhoneController.text.isNotEmpty) 'alternatePhone': _altPhoneController.text.trim(),
      'dateOfBirth': _dobController.text,
      'gender': _selectedGender!,
      if (_selectedBloodGroup != null) 'bloodGroup': _selectedBloodGroup,
      if (_selectedMaritalStatus != null) 'maritalStatus': _selectedMaritalStatus,
      'address': {
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'country': _countryController.text.trim(),
      },
      'sameAsPermanent': _sameAsPermanent,
      if (!_sameAsPermanent)
        'permanentAddress': {
          'street': _pStreetController.text.trim(),
          'city': _pCityController.text.trim(),
          'state': _pStateController.text.trim(),
          'pincode': _pPincodeController.text.trim(),
          'country': _pCountryController.text.trim(),
        },
      'department': _selectedDepartment!,
      'designation': _designationController.text.trim(),
      'dateOfJoining': _joiningDateController.text,
      'employmentType': _selectedEmploymentType!,
      if (_selectedWorkLocation != null) 'workLocation': _selectedWorkLocation,
      if (_reportingManagerController.text.isNotEmpty) 'reportingManager': _reportingManagerController.text.trim(),
      if (_ctcController.text.isNotEmpty) 'ctc': double.tryParse(_ctcController.text),
      'emergencyContact': {
        'name': _emergencyNameController.text.trim(),
        'relationship': _emergencyRelationController.text.trim(),
        'phone': _emergencyPhoneController.text.trim(),
      },
      'bankDetails': {
        if (_accountNumberController.text.isNotEmpty) 'accountNumber': _accountNumberController.text.trim(),
        if (_bankNameController.text.isNotEmpty) 'bankName': _bankNameController.text.trim(),
        if (_branchNameController.text.isNotEmpty) 'branchName': _branchNameController.text.trim(),
        if (_ifscController.text.isNotEmpty) 'ifscCode': _ifscController.text.trim().toUpperCase(),
        if (_selectedAccountType != null) 'accountType': _selectedAccountType,
      },
      'documents': {
        if (_aadharController.text.isNotEmpty) 'aadharNumber': _aadharController.text.trim(),
        if (_panController.text.isNotEmpty) 'panNumber': _panController.text.trim().toUpperCase(),
        if (_passportController.text.isNotEmpty) 'passportNumber': _passportController.text.trim(),
        if (_dlController.text.isNotEmpty) 'drivingLicense': _dlController.text.trim(),
      },
      'password': _passwordController.text,
    };

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signup(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Welcome aboard!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } else if (mounted) {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Registration failed');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account (${_currentPage + 1}/$_totalPages)'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: _currentPage == 0 ? () => Navigator.pop(context) : _previousPage,
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 4,
          ),

          // Step Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStepChip(0, 'Personal'),
                _buildStepChip(1, 'Address'),
                _buildStepChip(2, 'Work'),
                _buildStepChip(3, 'Bank'),
                _buildStepChip(4, 'Docs'),
              ],
            ),
          ),

          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildPersonalInfoPage(),
                _buildAddressPage(),
                _buildEmploymentPage(),
                _buildEmergencyBankPage(),
                _buildDocumentsPage(),
              ],
            ),
          ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: _currentPage == _totalPages - 1 ? 'Create Account' : 'Next',
                    isLoading: authProvider.isLoading,
                    onPressed: _currentPage == _totalPages - 1 ? _handleSignup : _nextPage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepChip(int index, String label) {
    final isActive = index == _currentPage;
    final isCompleted = index < _currentPage;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppTheme.successColor
                    : isActive
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primaryColor : AppTheme.textHint,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===== PAGE 1: Personal Information =====
  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Information', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Let\'s start with your basic details', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _firstNameController,
                    label: 'First Name *',
                    hint: 'John',
                    prefixIcon: Iconsax.user,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _lastNameController,
                    label: 'Last Name *',
                    hint: 'Doe',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _emailController,
              label: 'Email Address *',
              hint: 'john.doe@company.com',
              prefixIcon: Iconsax.sms,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v!.isEmpty) return 'Required';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'Invalid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number *',
              hint: '9876543210',
              prefixIcon: Iconsax.call,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v!.isEmpty) return 'Required';
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) return 'Invalid phone';
                return null;
              },
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _altPhoneController,
              label: 'Alternate Phone',
              hint: 'Optional',
              prefixIcon: Iconsax.call_add,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _dobController,
              label: 'Date of Birth *',
              hint: 'Select date',
              prefixIcon: Iconsax.calendar,
              readOnly: true,
              onTap: () => _selectDate(_dobController),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            _buildDropdown('Gender *', _selectedGender, AppConstants.genderOptions, (v) {
              setState(() => _selectedGender = v);
            }),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown('Blood Group', _selectedBloodGroup, AppConstants.bloodGroups, (v) {
                    setState(() => _selectedBloodGroup = v);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown('Marital Status', _selectedMaritalStatus, AppConstants.maritalStatusOptions, (v) {
                    setState(() => _selectedMaritalStatus = v);
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== PAGE 2: Address =====
  Widget _buildAddressPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Address', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),

            CustomTextField(
              controller: _streetController,
              label: 'Street Address *',
              hint: 'House No, Street, Locality',
              prefixIcon: Iconsax.home,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _cityController,
                    label: 'City *',
                    hint: 'Hyderabad',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _stateController,
                    label: 'State *',
                    hint: 'Telangana',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _pincodeController,
                    label: 'Pincode *',
                    hint: '500001',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _countryController,
                    label: 'Country',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Same as permanent checkbox
            CheckboxListTile(
              value: _sameAsPermanent,
              onChanged: (v) => setState(() => _sameAsPermanent = v!),
              title: const Text('Same as permanent address', style: TextStyle(fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.primaryColor,
            ),

            if (!_sameAsPermanent) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text('Permanent Address', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _pStreetController,
                label: 'Street Address *',
                hint: 'House No, Street, Locality',
                prefixIcon: Iconsax.home,
                validator: !_sameAsPermanent ? (v) => v!.isEmpty ? 'Required' : null : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _pCityController,
                      label: 'City *',
                      hint: 'City',
                      validator: !_sameAsPermanent ? (v) => v!.isEmpty ? 'Required' : null : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _pStateController,
                      label: 'State *',
                      hint: 'State',
                      validator: !_sameAsPermanent ? (v) => v!.isEmpty ? 'Required' : null : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _pPincodeController,
                      label: 'Pincode *',
                      hint: '500001',
                      keyboardType: TextInputType.number,
                      validator: !_sameAsPermanent
                          ? (v) {
                              if (v!.isEmpty) return 'Required';
                              if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Invalid';
                              return null;
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _pCountryController,
                      label: 'Country',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== PAGE 3: Employment =====
  Widget _buildEmploymentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employment Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Your professional information', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),

            _buildDropdown('Department *', _selectedDepartment, AppConstants.departments, (v) {
              setState(() => _selectedDepartment = v);
            }, required: true),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _designationController,
              label: 'Designation *',
              hint: 'Software Engineer',
              prefixIcon: Iconsax.briefcase,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _joiningDateController,
              label: 'Date of Joining *',
              hint: 'Select date',
              prefixIcon: Iconsax.calendar,
              readOnly: true,
              onTap: () => _selectDate(_joiningDateController),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            _buildDropdown('Employment Type *', _selectedEmploymentType, AppConstants.employmentTypes, (v) {
              setState(() => _selectedEmploymentType = v);
            }, required: true),
            const SizedBox(height: 16),

            _buildDropdown('Work Location', _selectedWorkLocation, AppConstants.workLocations, (v) {
              setState(() => _selectedWorkLocation = v);
            }),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _reportingManagerController,
              label: 'Reporting Manager',
              hint: 'Manager name',
              prefixIcon: Iconsax.user_octagon,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _ctcController,
              label: 'Annual CTC (₹)',
              hint: 'e.g., 500000',
              prefixIcon: Iconsax.money,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  // ===== PAGE 4: Emergency & Bank =====
  Widget _buildEmergencyBankPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Contact', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Person to contact in case of emergency', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),

            CustomTextField(
              controller: _emergencyNameController,
              label: 'Contact Name *',
              hint: 'Full name',
              prefixIcon: Iconsax.user,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _emergencyRelationController,
                    label: 'Relationship *',
                    hint: 'e.g., Father',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _emergencyPhoneController,
                    label: 'Phone *',
                    hint: '9876543210',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            Text('Bank Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('For salary processing', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),

            CustomTextField(
              controller: _accountNumberController,
              label: 'Account Number',
              hint: 'Enter account number',
              prefixIcon: Iconsax.bank,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _bankNameController,
                    label: 'Bank Name',
                    hint: 'e.g., SBI',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _branchNameController,
                    label: 'Branch',
                    hint: 'Branch name',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _ifscController,
                    label: 'IFSC Code',
                    hint: 'SBIN0001234',
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown('Account Type', _selectedAccountType, ['Savings', 'Current'], (v) {
                    setState(() => _selectedAccountType = v);
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== PAGE 5: Documents & Password =====
  Widget _buildDocumentsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[4],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Identity verification documents', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),

            CustomTextField(
              controller: _aadharController,
              label: 'Aadhar Number',
              hint: '123456789012',
              prefixIcon: Iconsax.card,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _panController,
              label: 'PAN Number',
              hint: 'ABCDE1234F',
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _passportController,
                    label: 'Passport No.',
                    hint: 'Optional',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _dlController,
                    label: 'Driving License',
                    hint: 'Optional',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            Text('Create Password', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Must contain uppercase, lowercase, number & special char', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),

            CustomTextField(
              controller: _passwordController,
              label: 'Password *',
              hint: 'Min 8 characters',
              prefixIcon: Iconsax.lock,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Iconsax.eye_slash : Iconsax.eye),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v!.isEmpty) return 'Required';
                if (v.length < 8) return 'Min 8 characters';
                if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])').hasMatch(v)) {
                  return 'Include upper, lower, digit & special char';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password *',
              hint: 'Re-enter password',
              prefixIcon: Iconsax.lock_1,
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Iconsax.eye_slash : Iconsax.eye),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v!.isEmpty) return 'Required';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged, {bool required = false}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: required ? (v) => v == null ? 'Required' : null : null,
      icon: const Icon(Iconsax.arrow_down_1, size: 20),
      isExpanded: true,
    );
  }
}
