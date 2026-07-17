const express = require('express');
const router = express.Router();

const Employee = require('../models/Employee');
const otpService = require('../services/otpService');
const { notifyAdminsOfSignup } = require('../services/notificationService');
const ApiResponse = require('../utils/apiResponse');
const { protect } = require('../middleware/auth');
const { catchAsync, AppError, AuthenticationError, NotFoundError, ConflictError } = require('../middleware/errorHandler');
const {
  validateSignup, validateLogin, validateOTP, validateEmail,
  validatePasswordChange, validateUpdateProfile, validatePasswordReset
} = require('../middleware/validate');
const logger = require('../utils/logger');

// POST /api/auth/signup - complete a previously email-verified registration
router.post('/signup', validateSignup, catchAsync(async (req, res) => {
  const {
    firstName, lastName, email, phone, alternatePhone,
    dateOfBirth, gender, bloodGroup, maritalStatus,
    address, permanentAddress, sameAsPermanent,
    department, designation, dateOfJoining, employmentType,
    workLocation, reportingManager, ctc,
    emergencyContact, bankDetails, documents, education, password
  } = req.body;

  // Email/phone already registered? (duplicate-key race is also mapped to 409 by the error handler)
  const existing = await Employee.findOne({ $or: [{ email }, { phone }] });
  if (existing) {
    if (existing.email === email) throw new ConflictError('Email already registered. Please login.');
    if (existing.phone === phone) throw new ConflictError('Phone number already registered.');
  }

  const { verificationToken } = req.body;
  const pending = await otpService.assertVerifiedSignup(email, verificationToken);

  // Store signup data - starts as pending until an admin approves it
  const signupData = {
    firstName, lastName, email, phone, alternatePhone,
    dateOfBirth, gender, bloodGroup, maritalStatus,
    address,
    permanentAddress: sameAsPermanent ? address : permanentAddress,
    sameAsPermanent,
    department, designation, dateOfJoining, employmentType,
    workLocation, reportingManager, ctc,
    emergencyContact, bankDetails, documents, education,
    password,
    isEmailVerified: true
  };

  const employee = await Employee.create(signupData);
  await pending.deleteOne();
  const token = employee.getSignedJwtToken();

  logger.info(`New employee registered: ${employee.employeeId} - ${employee.fullName}`);

  // Let admins know a registration is waiting for their decision (non-blocking)
  notifyAdminsOfSignup(employee);

  return ApiResponse.success(res, 201, 'Registration submitted for admin approval.', {
    token,
    employee,
    approvalStatus: employee.approvalStatus
  });
}));

// POST /api/auth/login
router.post('/login', validateLogin, catchAsync(async (req, res) => {
  const { email, password } = req.body;

  const employee = await Employee.findOne({ email }).select('+password');
  if (!employee) throw new AuthenticationError('Invalid email or password');

  if (employee.isLocked) {
    const lockTime = Math.ceil((employee.lockUntil - Date.now()) / 60000);
    throw new AppError(`Account locked. Try in ${lockTime} min.`, 423);
  }

  if (!employee.isActive) throw new AuthenticationError('Account deactivated');

  const isMatch = await employee.comparePassword(password);
  if (!isMatch) {
    await employee.incrementLoginAttempts();
    throw new AuthenticationError('Invalid email or password');
  }

  await employee.resetLoginAttempts();
  const token = employee.getSignedJwtToken();

  logger.info(`Login: ${employee.employeeId}`);

  return ApiResponse.success(res, 200, 'Login successful', {
    token,
    employee: {
      id: employee._id,
      employeeId: employee.employeeId,
      firstName: employee.firstName,
      lastName: employee.lastName,
      email: employee.email,
      phone: employee.phone,
      department: employee.department,
      designation: employee.designation,
      role: employee.role,
      isEmailVerified: employee.isEmailVerified,
      isActive: employee.isActive,
      approvalStatus: employee.approvalStatus
    }
  });
}));

// POST /api/auth/send-otp - Send OTP for signup (email_verification), login, or password reset
router.post('/send-otp', validateEmail, catchAsync(async (req, res) => {
  const { email, purpose } = req.body;
  const { verificationToken } = await otpService.requestOTP({ email, purpose: purpose || 'login' });
  return ApiResponse.success(res, 200, 'OTP sent successfully.', { verificationToken });
}));

// POST /api/auth/verify-otp - Verify OTP for signup, login, or password reset
router.post('/verify-otp', validateOTP, catchAsync(async (req, res) => {
  const { email, otp, purpose, verificationToken } = req.body;
  const otpPurpose = purpose || 'email_verification';

  await otpService.verifyOTP({ email, otp, purpose: otpPurpose, verificationToken });

  if (otpPurpose === 'email_verification') {
    return ApiResponse.success(res, 200, 'Email verified. Complete your registration.', {
      verified: true,
      verificationToken
    });
  }

  if (otpPurpose === 'login') {
    // OTP Login flow
    const employee = await Employee.findOne({ email });
    if (!employee) throw new NotFoundError('Employee');
    if (!employee.isActive) throw new AppError('Account deactivated', 401);

    const token = employee.getSignedJwtToken();
    logger.info(`OTP login: ${employee.employeeId}`);

    return ApiResponse.success(res, 200, 'OTP verified. Login successful.', {
      verified: true,
      token,
      employee: {
        id: employee._id,
        employeeId: employee.employeeId,
        firstName: employee.firstName,
        lastName: employee.lastName,
        email: employee.email,
        department: employee.department,
        approvalStatus: employee.approvalStatus
      }
    });
  }

  // password_reset
  return ApiResponse.success(res, 200, 'OTP verified successfully.', { verified: true });
}));

// POST /api/auth/reset-password
router.post('/reset-password', validatePasswordReset, catchAsync(async (req, res) => {
  const { email, otp, newPassword, verificationToken } = req.body;

  await otpService.verifyOTP({ email, otp, purpose: 'password_reset', verificationToken });

  const employee = await Employee.findOne({ email }).select('+password');
  if (!employee) throw new NotFoundError('Employee');

  employee.password = newPassword;
  employee.passwordChangedAt = new Date();
  await employee.save();

  logger.info(`Password reset: ${employee.employeeId}`);
  return ApiResponse.success(res, 200, 'Password reset successful');
}));

// GET /api/auth/me
router.get('/me', protect, catchAsync(async (req, res) => {
  const employee = await Employee.findById(req.employee._id);
  if (!employee) throw new NotFoundError('Employee');
  return ApiResponse.success(res, 200, 'Profile fetched', { employee });
}));

// PUT /api/auth/change-password
router.put('/change-password', protect, validatePasswordChange, catchAsync(async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const employee = await Employee.findById(req.employee._id).select('+password');

  const isMatch = await employee.comparePassword(currentPassword);
  if (!isMatch) throw new AuthenticationError('Wrong password');

  employee.password = newPassword;
  employee.passwordChangedAt = new Date();
  await employee.save();

  const token = employee.getSignedJwtToken();
  logger.info(`Password changed: ${employee.employeeId}`);
  return ApiResponse.success(res, 200, 'Password changed', { token });
}));

// PUT /api/auth/update-profile
router.put('/update-profile', protect, validateUpdateProfile, catchAsync(async (req, res) => {
  const fields = ['firstName', 'lastName', 'phone', 'address', 'emergencyContact', 'profilePhoto'];
  const updates = {};
  fields.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });

  const employee = await Employee.findByIdAndUpdate(req.employee._id, { $set: updates }, { new: true });
  if (!employee) throw new NotFoundError('Employee');

  return ApiResponse.success(res, 200, 'Profile updated', { employee });
}));

module.exports = router;
