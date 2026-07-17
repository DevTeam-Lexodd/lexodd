const express = require('express');
const router = express.Router();

const Employee = require('../models/Employee');
const otpService = require('../services/otpService');
const ApiResponse = require('../utils/apiResponse');
const { catchAsync, AppError, NotFoundError } = require('../middleware/errorHandler');
const { validateEmail, validateOTP } = require('../middleware/validate');
const logger = require('../utils/logger');

// POST /api/otp/send
// Shared logic with /api/auth/send-otp via otpService.requestOTP:
// - email_verification: 409 if the email is already registered
// - login / password_reset: 404 if no account exists
router.post('/send', validateEmail, catchAsync(async (req, res) => {
  const { email, purpose } = req.body;
  const { verificationToken } = await otpService.requestOTP({ email, purpose });
  return ApiResponse.success(res, 200, 'OTP sent to email', { verificationToken });
}));

// POST /api/otp/verify
router.post('/verify', validateOTP, catchAsync(async (req, res) => {
  const { email, otp, purpose, verificationToken } = req.body;
  const otpPurpose = purpose || 'email_verification';

  await otpService.verifyOTP({ email, otp, purpose: otpPurpose, verificationToken });

  if (otpPurpose === 'login') {
    const employee = await Employee.findOne({ email });
    if (!employee) throw new NotFoundError('Employee');
    if (!employee.isActive) throw new AppError('Account deactivated', 401);

    const token = employee.getSignedJwtToken();
    logger.info(`OTP login: ${employee.employeeId}`);

    return ApiResponse.success(res, 200, 'OTP verified', {
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

  if (otpPurpose === 'email_verification') {
    // PendingSignup was created by the service - signup can now proceed with this token
    return ApiResponse.success(res, 200, 'Email verified. Complete your registration.', {
      verified: true,
      verificationToken
    });
  }

  return ApiResponse.success(res, 200, 'OTP verified successfully.', { verified: true });
}));

module.exports = router;
