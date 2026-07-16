const express = require('express');
const router = express.Router();

const Employee = require('../models/Employee');
const OTP = require('../models/OTP');
const PendingSignup = require('../models/PendingSignup');
const { sendOTP } = require('../utils/email');
const ApiResponse = require('../utils/apiResponse');
const { protect } = require('../middleware/auth');
const { catchAsync, AppError, AuthenticationError, NotFoundError } = require('../middleware/errorHandler');
const {
  validateSignup, validateLogin, validateOTP, validateEmail,
  validatePasswordChange, validateUpdateProfile, validatePasswordReset
} = require('../middleware/validate');
const logger = require('../utils/logger');
const crypto = require('crypto');

// Hash verification token for storage
const hashToken = (token) => crypto.createHash('sha256').update(token).digest('hex');

// POST /api/auth/signup - Store signup data, send OTP, return verificationToken
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

  // Check if employee already exists
  const existing = await Employee.findOne({ $or: [{ email }, { phone }] });
  if (existing) {
    if (existing.email === email) throw new AppError('Email already registered', 400);
    if (existing.phone === phone) throw new AppError('Phone already registered', 400);
  }

  // Check for pending signup with same email/phone
  const pending = await PendingSignup.findOne({ email });
  if (pending) {
    // Clean up old pending signup
    await PendingSignup.deleteOne({ _id: pending._id });
    await OTP.deleteMany({ email, purpose: 'email_verification' });
  }

  // Generate verification token
  const verificationToken = crypto.randomBytes(32).toString('hex');
  const verificationTokenHash = hashToken(verificationToken);

  // Store signup data in PendingSignup
  const signupData = {
    firstName, lastName, email, phone, alternatePhone,
    dateOfBirth, gender, bloodGroup, maritalStatus,
    address,
    permanentAddress: sameAsPermanent ? address : permanentAddress,
    sameAsPermanent,
    department, designation, dateOfJoining, employmentType,
    workLocation, reportingManager, ctc,
    emergencyContact, bankDetails, documents, education,
    password
  };

  await PendingSignup.create({
    verificationTokenHash,
    data: signupData,
    email,
    expiresAt: new Date(Date.now() + (process.env.OTP_EXPIRY || 10) * 60 * 1000) // 10 min expiry
  });

  // Create and send OTP
  const { otp } = await OTP.createOTP(email, 'email_verification');

  try {
    const emailResult = await sendOTP(email, otp, 'email_verification');
    if (!emailResult.success) {
      throw new AppError('Unable to send the verification email. Check the email service configuration and try again.', 502);
    }
  } catch (error) {
    await PendingSignup.deleteOne({ verificationTokenHash });
    await OTP.deleteMany({ email, purpose: 'email_verification' });
    throw error;
  }

  logger.info(`Signup initiated for: ${email}`);

  return ApiResponse.success(res, 201, 'Verification code sent to your email. Please verify to complete registration.', {
    verificationToken
  });
}));

// POST /api/auth/login - Password only login
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

// POST /api/auth/send-otp - Send OTP for login or password reset
router.post('/send-otp', validateEmail, catchAsync(async (req, res) => {
  const { email, purpose } = req.body;
  const otpPurpose = purpose || 'login'; // Default to login for OTP-based login
  const validPurposes = ['login', 'password_reset'];

  if (!validPurposes.includes(otpPurpose)) {
    throw new AppError('Invalid purpose', 400);
  }

  if (otpPurpose === 'password_reset') {
    const employee = await Employee.findOne({ email });
    if (!employee) throw new NotFoundError('Account');
  } else if (otpPurpose === 'login') {
    const employee = await Employee.findOne({ email });
    if (!employee) throw new NotFoundError('Account');
  }

  // Rate limit: 3 per 15 min
  const recent = await OTP.countDocuments({
    email, purpose: otpPurpose,
    createdAt: { $gt: new Date(Date.now() - 15 * 60 * 1000) }
  });
  if (recent >= 3) throw new AppError('Too many requests. Wait 15 min.', 429);

  const { otp, verificationToken } = await OTP.createOTP(email, otpPurpose);

  try {
    const emailResult = await sendOTP(email, otp, otpPurpose);
    if (!emailResult.success) throw new AppError('Unable to send OTP email. Please try again later.', 502);
  } catch (err) {
    logger.warn(`Email failed: ${err.message}`);
    throw err;
  }

  return ApiResponse.success(res, 200, 'OTP sent to email', { verificationToken });
}));

// POST /api/auth/verify-otp - Verify OTP for signup, login, or password reset
router.post('/verify-otp', validateOTP, catchAsync(async (req, res) => {
  const { email, otp, purpose, verificationToken } = req.body;
  const otpPurpose = purpose || 'email_verification';

  const result = await OTP.verifyOTP(email, otp, otpPurpose, verificationToken);
  if (!result.valid) throw new AppError(result.message, 400);

  if (otpPurpose === 'email_verification') {
    // Signup flow: Create employee from pending signup data
    const verificationTokenHash = hashToken(verificationToken);
    const pending = await PendingSignup.findOne({ verificationTokenHash });

    if (!pending) {
      throw new AppError('Invalid or expired verification token. Please start signup again.', 400);
    }

    // Double-check email/phone not taken (race condition)
    const existing = await Employee.findOne({ $or: [{ email: pending.data.email }, { phone: pending.data.phone }] });
    if (existing) {
      await PendingSignup.deleteOne({ _id: pending._id });
      if (existing.email === pending.data.email) throw new AppError('Email already registered', 400);
      if (existing.phone === pending.data.phone) throw new AppError('Phone already registered', 400);
    }

    // Create employee
    const employee = await Employee.create(pending.data);

    // Clean up
    await PendingSignup.deleteOne({ _id: pending._id });

    const token = employee.getSignedJwtToken();

    logger.info(`New employee registered: ${employee.employeeId} - ${employee.fullName}`);

    return ApiResponse.success(res, 201, 'Registration successful. Welcome!', {
      token,
      employee: {
        id: employee._id,
        employeeId: employee.employeeId,
        firstName: employee.firstName,
        lastName: employee.lastName,
        email: employee.email,
        department: employee.department,
        designation: employee.designation,
        isEmailVerified: true
      }
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
      verified: true, token,
      employee: {
        id: employee._id, employeeId: employee.employeeId,
        firstName: employee.firstName, lastName: employee.lastName,
        email: employee.email, department: employee.department
      }
    });
  }

  if (otpPurpose === 'password_reset') {
    // Password reset - just verify, actual reset is separate endpoint
    return ApiResponse.success(res, 200, result.message, { verified: true });
  }

  return ApiResponse.success(res, 200, result.message, { verified: true });
}));

// POST /api/auth/reset-password
router.post('/reset-password', validatePasswordReset, catchAsync(async (req, res) => {
  const { email, otp, newPassword, verificationToken } = req.body;

  const result = await OTP.verifyOTP(email, otp, 'password_reset', verificationToken);
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
  const fields = ['firstName', 'lastName', 'phone', 'address', 'emergencyContact', 'profilePhoto'];
  const updates = {};
  fields.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });

  const employee = await Employee.findByIdAndUpdate(req.employee._id, { $set: updates }, { new: true });
  if (!employee) throw new NotFoundError('Employee');

  return ApiResponse.success(res, 200, 'Profile updated', { employee });
}));

module.exports = router;