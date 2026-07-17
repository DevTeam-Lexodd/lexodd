import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../config/constant.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/home_screen.dart';
import 'otp_screen.dart';

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

  // Controllers
  final _first = TextEditingController(), _last = TextEditingController();
  final _email = TextEditingController(), _phone = TextEditingController();
  final _dob = TextEditingController(), _street = TextEditingController();
  final _city = TextEditingController(), _state = TextEditingController();
  final _pincode = TextEditingController(),
      _country = TextEditingController(text: 'India');
  final _designation = TextEditingController(),
      _joiningDate = TextEditingController();
  final _manager = TextEditingController(), _ctc = TextEditingController();
  final _emergName = TextEditingController(),
      _emergRelation = TextEditingController(),
      _emergPhone = TextEditingController();
  final _accNo = TextEditingController(),
      _bank = TextEditingController(),
      _branch = TextEditingController(),
      _ifsc = TextEditingController();
  final _aadhar = TextEditingController(), _pan = TextEditingController();
  final _password = TextEditingController(),
      _confirmPassword = TextEditingController();
  bool _obscurePass = true, _obscureConfirm = true;
  bool _emailVerified = false;
  String? _verificationToken;

  String? _gender,
      _bloodGroup,
      _department,
      _employmentType,
      _workLocation,
      _accountType;
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _country.dispose();
    _designation.dispose();
    _joiningDate.dispose();
    _manager.dispose();
    _ctc.dispose();
    _emergName.dispose();
    _emergRelation.dispose();
    _emergPhone.dispose();
    _accNo.dispose();
    _bank.dispose();
    _branch.dispose();
    _ifsc.dispose();
    _aadhar.dispose();
    _pan.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_formKeys[_currentPage].currentState!.validate()) {
      if (_currentPage < _totalPages - 1) {
        _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _selectDate(TextEditingController ctrl,
      {bool isDob = false}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: isDob ? DateTime(now.year - 25, now.month, now.day) : now,
        firstDate: DateTime(1950),
        // Backend requires employees to be at least 18 years old
        lastDate: isDob ? DateTime(now.year - 18, now.month, now.day) : now);
    if (date != null) ctrl.text = DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _handleSignup() async {
    if (!_formKeys[_currentPage].currentState!.validate()) return;
    if (_password.text != _confirmPassword.text) {
      _showError('Passwords do not match');
      return;
    }

    // The server rejects signup without a recently verified email token -
    // fail fast here instead of after a network call.
    if (!_emailVerified || _verificationToken == null) {
      _restartEmailVerification('Verify your email before creating the account.');
      return;
    }

    final data = {
      'firstName': _first.text.trim(),
      'lastName': _last.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'dateOfBirth': _dob.text,
      'gender': _gender!,
      if (_bloodGroup != null) 'bloodGroup': _bloodGroup,
      'department': _department!,
      'designation': _designation.text.trim(),
      'dateOfJoining': _joiningDate.text,
      'employmentType': _employmentType!,
      if (_workLocation != null) 'workLocation': _workLocation,
      if (_manager.text.isNotEmpty) 'reportingManager': _manager.text.trim(),
      if (_ctc.text.trim().isNotEmpty)
        'ctc': double.tryParse(_ctc.text.trim()),
      'address': {
        'street': _street.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'pincode': _pincode.text.trim(),
        'country': _country.text.trim()
      },
      'emergencyContact': {
        'name': _emergName.text.trim(),
        'relationship': _emergRelation.text.trim(),
        'phone': _emergPhone.text.trim()
      },
      'bankDetails': {
        if (_accNo.text.isNotEmpty) 'accountNumber': _accNo.text.trim(),
        if (_bank.text.isNotEmpty) 'bankName': _bank.text.trim(),
        if (_branch.text.isNotEmpty) 'branchName': _branch.text.trim(),
        if (_ifsc.text.isNotEmpty) 'ifscCode': _ifsc.text.trim().toUpperCase(),
        if (_accountType != null) 'accountType': _accountType,
      },
      'documents': {
        if (_aadhar.text.trim().isNotEmpty)
          'aadharNumber': _aadhar.text.trim(),
        if (_pan.text.trim().isNotEmpty)
          'panNumber': _pan.text.trim().toUpperCase()
      },
      'password': _password.text,
      'verificationToken': _verificationToken,
    };

    final auth = context.read<AuthProvider>();
    final registered = await auth.signup(data);
    if (!mounted) return;

    if (registered) {
      // The account exists and the user is signed in (pending approval) -
      // drop the whole auth stack so "back" cannot return to login/signup.
      Navigator.of(context)
          .pushNamedAndRemoveUntil(HomeScreen.routeName, (_) => false);
      return;
    }

    // The verified-email token expires 10 minutes after the OTP is verified
    // (PENDING_SIGNUP_TTL_MS on the server). Keep everything the user typed
    // and send them back to re-verify instead of dead-ending the form.
    if (auth.errorCode == 'ERR_EMAIL_NOT_VERIFIED') {
      _restartEmailVerification(auth.errorMessage ??
          'Email verification expired. Please verify again to finish signing up.');
      return;
    }

    _showError(auth.errorMessage ?? 'Registration failed');
  }

  /// Sends the user back to the email-verification gate without losing the
  /// form data they already filled in.
  void _restartEmailVerification(String message) {
    // The wizard is still on screen here, so the controller is attached and
    // can be reset safely before the verification gate replaces it.
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    setState(() {
      _emailVerified = false;
      _verificationToken = null;
      _currentPage = 0;
    });
    _showError(message);
  }

  Future<void> _startEmailVerification() async {
    final email = _email.text.trim();
    if (!AppValidators.isValidEmail(email)) {
      _showError('Enter a valid email address');
      return;
    }
    final auth = context.read<AuthProvider>();
    final token = await auth.sendOTP(email, purpose: 'email_verification');
    if (!mounted) return;
    if (token == null) {
      _showError(auth.errorMessage ?? 'Unable to send OTP');
      return;
    }
    _showSuccess('OTP sent to $email');
    await _openOTPScreen(email, token);
  }

  Future<void> _openOTPScreen(String email, String verificationToken) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OTPScreen(
        email: email,
        isEmailVerification: true,
        displayAsDialog: true,
        verificationToken: verificationToken,
        onVerified: (verifiedToken) {
          Navigator.of(context, rootNavigator: true).pop();
          setState(() {
            // Store the token that was actually verified. It differs from the
            // original one whenever the user resent the OTP in the dialog, and
            // signup is rejected server-side if a stale token is submitted.
            _verificationToken = verifiedToken;
            _emailVerified = true;
          });
        },
      ),
    );
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.successColor));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!_emailVerified) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verify your email')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight -
                    48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 36),
                  const Icon(Iconsax.sms,
                      size: 56, color: AppTheme.primaryColor),
                  const SizedBox(height: 20),
                  const Text('Create your account',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                      'Enter your email first. We will send a verification code before asking for your details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 32),
                  CustomTextField(
                      controller: _email,
                      label: 'Email *',
                      hint: 'you@company.com',
                      prefixIcon: Iconsax.sms,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  CustomButton(
                      text: 'Send OTP',
                      isLoading: auth.isLoading,
                      onPressed: _startEmailVerification),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
          title: Text('Create Account (${_currentPage + 1}/$_totalPages)'),
          leading: IconButton(
              icon: const Icon(Iconsax.arrow_left),
              onPressed: _currentPage == 0
                  ? () => Navigator.pop(context)
                  : _prevPage)),
      body: Column(children: [
        LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            minHeight: 4),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              _stepChip(0, 'Personal'),
              _stepChip(1, 'Address'),
              _stepChip(2, 'Work'),
              _stepChip(3, 'Bank'),
              _stepChip(4, 'Docs'),
            ])),
        Expanded(
            child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
              _personalPage(),
              _addressPage(),
              _workPage(),
              _bankPage(),
              _docsPage()
            ])),
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ]),
            child: Row(children: [
              if (_currentPage > 0)
                Expanded(
                    child: OutlinedButton(
                        onPressed: _prevPage, child: const Text('Previous'))),
              if (_currentPage > 0) const SizedBox(width: 16),
              Expanded(
                  flex: 2,
                  child: CustomButton(
                      text: _currentPage == _totalPages - 1
                          ? 'Create Account'
                          : 'Next',
                      isLoading: auth.isLoading,
                      onPressed: _currentPage == _totalPages - 1
                          ? _handleSignup
                          : _nextPage)),
            ])),
      ]),
    );
  }

  Widget _stepChip(int i, String label) {
    final active = i == _currentPage, done = i < _currentPage;
    return Expanded(
        child: Column(children: [
      Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? AppTheme.successColor
                  : active
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300),
          child: Center(
              child: done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text('${i + 1}',
                      style: TextStyle(
                          color: active ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)))),
      const SizedBox(height: 4),
      FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppTheme.primaryColor : AppTheme.textHint))),
    ]));
  }

  Widget _personalPage() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
            key: _formKeys[0],
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Basic details',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                    child: CustomTextField(
                        controller: _first,
                        label: 'First Name *',
                        hint: 'John',
                        validator: AppValidators.personName)),
                const SizedBox(width: 12),
                Expanded(
                    child: CustomTextField(
                        controller: _last,
                        label: 'Last Name *',
                        hint: 'Doe',
                        validator: AppValidators.personName)),
              ]),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _email,
                  label: 'Email *',
                  hint: 'john@company.com',
                  prefixIcon: Iconsax.sms,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                  validator: AppValidators.email),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _phone,
                  label: 'Phone *',
                  hint: '9876543210',
                  prefixIcon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                  validator: AppValidators.phone),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _dob,
                  label: 'Date of Birth *',
                  hint: 'Select date',
                  prefixIcon: Iconsax.calendar,
                  readOnly: true,
                  onTap: () => _selectDate(_dob, isDob: true),
                  validator: AppValidators.required),
              const SizedBox(height: 16),
              _dropdown('Gender *', _gender, AppConstants.genderOptions,
                  (v) => setState(() => _gender = v),
                  required: true),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _dropdown(
                        'Blood Group',
                        _bloodGroup,
                        AppConstants.bloodGroups,
                        (v) => setState(() => _bloodGroup = v))),
                const SizedBox(width: 12),
                Expanded(
                    child: _dropdown(
                        'Department *',
                        _department,
                        AppConstants.departments,
                        (v) => setState(() => _department = v),
                        required: true)),
              ]),
            ])));
  }

  Widget _addressPage() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
            key: _formKeys[1],
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              CustomTextField(
                  controller: _street,
                  label: 'Street *',
                  hint: 'House No, Street',
                  prefixIcon: Iconsax.home,
                  validator: AppValidators.required),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: CustomTextField(
                        controller: _city,
                        label: 'City *',
                        hint: 'Hyderabad',
                        validator: AppValidators.required)),
                const SizedBox(width: 12),
                Expanded(
                    child: CustomTextField(
                        controller: _state,
                        label: 'State *',
                        hint: 'Telangana',
                        validator: AppValidators.required)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: CustomTextField(
                        controller: _pincode,
                        label: 'Pincode *',
                        hint: '500001',
                        keyboardType: TextInputType.number,
                        validator: AppValidators.pincode)),
                const SizedBox(width: 12),
                Expanded(
                    child: CustomTextField(
                        controller: _country, label: 'Country')),
              ]),
            ])));
  }

  Widget _workPage() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
            key: _formKeys[2],
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Employment Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              CustomTextField(
                  controller: _designation,
                  label: 'Designation *',
                  hint: 'Software Engineer',
                  prefixIcon: Iconsax.briefcase,
                  validator: AppValidators.required),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _joiningDate,
                  label: 'Joining Date *',
                  hint: 'Select date',
                  prefixIcon: Iconsax.calendar,
                  readOnly: true,
                  onTap: () => _selectDate(_joiningDate),
                  validator: AppValidators.required),
              const SizedBox(height: 16),
              _dropdown(
                  'Employment Type *',
                  _employmentType,
                  AppConstants.employmentTypes,
                  (v) => setState(() => _employmentType = v),
                  required: true),
              const SizedBox(height: 16),
              _dropdown(
                  'Work Location',
                  _workLocation,
                  AppConstants.workLocations,
                  (v) => setState(() => _workLocation = v)),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _manager,
                  label: 'Reporting Manager',
                  hint: 'Manager name',
                  prefixIcon: Iconsax.user_octagon),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _ctc,
                  label: 'Annual CTC (₹)',
                  hint: '500000',
                  prefixIcon: Iconsax.money,
                  keyboardType: TextInputType.number,
                  validator: AppValidators.amount),
            ])));
  }

  Widget _bankPage() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
            key: _formKeys[3],
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Emergency Contact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              CustomTextField(
                  controller: _emergName,
                  label: 'Contact Name *',
                  hint: 'Full name',
                  validator: AppValidators.required),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: CustomTextField(
                        controller: _emergRelation,
                        label: 'Relationship *',
                        hint: 'Father',
                        validator: AppValidators.required)),
                const SizedBox(width: 12),
                Expanded(
                    child: CustomTextField(
                        controller: _emergPhone,
                        label: 'Phone *',
                        hint: '9876543210',
                        keyboardType: TextInputType.phone,
                        validator: AppValidators.phone)),
              ]),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Bank Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              CustomTextField(
                  controller: _accNo,
                  label: 'Account Number',
                  hint: 'Account number',
                  prefixIcon: Iconsax.bank,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: CustomTextField(
                        controller: _bank, label: 'Bank Name', hint: 'SBI')),
                const SizedBox(width: 12),
                Expanded(
                    child: CustomTextField(
                        controller: _branch,
                        label: 'Branch',
                        hint: 'Branch name')),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: CustomTextField(
                        controller: _ifsc,
                        label: 'IFSC Code',
                        hint: 'SBIN0001234',
                        textCapitalization: TextCapitalization.characters,
                        validator: AppValidators.ifsc)),
                const SizedBox(width: 12),
                Expanded(
                    child: _dropdown(
                        'Account Type',
                        _accountType,
                        ['Savings', 'Current'],
                        (v) => setState(() => _accountType = v))),
              ]),
            ])));
  }

  Widget _docsPage() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
            key: _formKeys[4],
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Documents & Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              CustomTextField(
                  controller: _aadhar,
                  label: 'Aadhar Number',
                  hint: '123456789012',
                  prefixIcon: Iconsax.card,
                  keyboardType: TextInputType.number,
                  validator: AppValidators.aadhar),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _pan,
                  label: 'PAN Number',
                  hint: 'ABCDE1234F',
                  textCapitalization: TextCapitalization.characters,
                  validator: AppValidators.pan),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Create Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              CustomTextField(
                  controller: _password,
                  label: 'Password *',
                  hint: 'Min 8 chars',
                  prefixIcon: Iconsax.lock,
                  obscureText: _obscurePass,
                  suffixIcon: IconButton(
                      icon:
                          Icon(_obscurePass ? Iconsax.eye_slash : Iconsax.eye),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass)),
                  validator: AppValidators.password),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _confirmPassword,
                  label: 'Confirm Password *',
                  hint: 'Re-enter',
                  prefixIcon: Iconsax.lock_1,
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                      icon: Icon(
                          _obscureConfirm ? Iconsax.eye_slash : Iconsax.eye),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm)),
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (v != _password.text) return 'Passwords mismatch';
                    return null;
                  }),
            ])));
  }

  Widget _dropdown(String label, String? value, List<String> items,
      Function(String?) onChanged,
      {bool required = false}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: required ? (v) => v == null ? 'Required' : null : null,
      icon: const Icon(Iconsax.arrow_down_1, size: 20),
      isExpanded: true,
    );
  }
}
