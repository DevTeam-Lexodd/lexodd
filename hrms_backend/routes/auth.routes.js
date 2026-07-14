const express = require('express');
const router = express.Router();

const Employee = require('../models/Employee');
const OTP = require('../models/OTP');
const { sendOTP } = require('../utils/email');
const ApiResponse = require('../utils/apiResponse');
const { protect } = require('../middleware/auth');
const { catchAsync, AppError, AuthenticationError, NotFoundError } = require('../middleware/errorHandler');
const {
  validateSignup, validateLogin, validateOTP, validateEmail,
  validatePasswordChange, validateUpdateProfile
} = require('../middleware/validate');
const logger = require('../utils/logger');

// POST /api/auth/signup
router.post('/signup', validateSignup, catchAsync(async (req, res) => {
  const {
    firstName, lastName, email, phone, alternatePhone,
    dateOfBirth, gender, bloodGroup, maritalStatus,
    address, permanentAddress, sameAsPermanent,
    department, designation, dateOfJoining, employmentType,
    workLocation, reportingManager, ctc,
    emergencyContact, bankDetails, documents, education,
    password
  } = req.body;

  // Check if exists
  const existing = await Employee.findOne({ $or: [{ email }, { phone }] });
  if (existing) {
    if (existing.email === email) throw new AppError('Email already registered', 400);
    if (existing.phone === phone) throw new AppError('Phone already registered', 400);
  }

  // Create employee
  const employee = await Employee.create({
    firstName, lastName, email, phone, alternatePhone,
    dateOfBirth, gender, bloodGroup, maritalStatus,
    address,
    permanentAddress: sameAsPermanent ? address : permanentAddress,
    sameAsPermanent,
    department, designation, dateOfJoining, employmentType,
    workLocation, reportingManager, ctc,
    emergencyContact, bankDetails, documents, education,
    password
  });

  // Send OTP via Brevo
  try {
    const otp = await OTP.createOTP(email, 'email_verification');
    logger.info(`OTP for ${email}: ${otp}`);
    await sendOTP(email, otp, 'email_verification');
  } catch (err) {
    logger.warn(`OTP send failed: ${err.message}`);
  }

  const token = employee.getSignedJwtToken();
  employee.password = undefined;

  logger.info(`New employee: ${employee.employeeId} - ${employee.fullName}`);

  return ApiResponse.success(res, 201, 'Registration successful. Please verify email.', {
    token,
    employee: {
      id: employee._id,
      employeeId: employee.employeeId,
      firstName: employee.firstName,
      lastName: employee.lastName,
      email: employee.email,
      department: employee.department,
      designation: employee.designation,
      isEmailVerified: employee.isEmailVerified
    }
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
      isEmailVerified: employee.isEmailVerified
    }
  });
}));

// POST /api/auth/send-otp
router.post('/send-otp', validateEmail, catchAsync(async (req, res) => {
  const { email, purpose } = req.body;

  if (purpose === 'password_reset') {
    const employee = await Employee.findOne({ email });
    if (!employee) throw new NotFoundError('Account');
  }

  const otp = await OTP.createOTP(email, purpose || 'email_verification');
  logger.info(`OTP for ${email}: ${otp}`);

  try {
    await sendOTP(email, otp, purpose || 'email_verification');
  } catch (err) {
    logger.warn(`Email failed: ${err.message}`);
    if (process.env.NODE_ENV === 'development') {
      return ApiResponse.success(res, 200, `OTP: ${otp} (dev mode - email failed)`);
    }
  }

  return ApiResponse.success(res, 200, 'OTP sent to email');
}));

// POST /api/auth/verify-otp
router.post('/verify-otp', validateOTP, catchAsync(async (req, res) => {
  const { email, otp, purpose } = req.body;

  const result = await OTP.verifyOTP(email, otp, purpose || 'email_verification');
  if (!result.valid) throw new AppError(result.message, 400);

  if (purpose === 'email_verification') {
    await Employee.findOneAndUpdate({ email }, { isEmailVerified: true });
  }

  return ApiResponse.success(res, 200, result.message, { verified: true });
}));

// POST /api/auth/reset-password
router.post('/reset-password', catchAsync(async (req, res) => {
  const { email, otp, newPassword } = req.body;

  if (!email || !otp || !newPassword) {
    throw new AppError('Email, OTP and password required', 400);
  }

  const result = await OTP.verifyOTP(email, otp, 'password_reset');
  if (!result.valid) throw new AppError(result.message, 400);

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
  const fields = ['firstName', 'lastName', 'phone', 'address', 'emergencyContact'];
  const updates = {};
  fields.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });

  const employee = await Employee.findByIdAndUpdate(req.employee._id, { $set: updates }, { new: true });
  if (!employee) throw new NotFoundError('Employee');

  return ApiResponse.success(res, 200, 'Profile updated', { employee });
}));

module.exports = router;
