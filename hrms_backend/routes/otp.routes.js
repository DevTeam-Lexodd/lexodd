const express = require('express');
const router = express.Router();

const OTP = require('../models/OTP');
const Employee = require('../models/Employee');
const { sendOTP } = require('../utils/email');
const ApiResponse = require('../utils/apiResponse');
const { catchAsync, AppError, NotFoundError } = require('../middleware/errorHandler');
const { validateEmail, validateOTP } = require('../middleware/validate');
const logger = require('../utils/logger');

// POST /api/otp/send
router.post('/send', validateEmail, catchAsync(async (req, res) => {
  const { email, purpose } = req.body;
  const validPurposes = ['email_verification', 'password_reset', 'login'];

  if (!validPurposes.includes(purpose)) {
    throw new AppError('Invalid purpose', 400);
  }

  if (purpose === 'password_reset') {
    const employee = await Employee.findOne({ email });
    if (!employee) throw new NotFoundError('Account');
  }

  // Rate limit: 3 per 15 min
  const recent = await OTP.countDocuments({
    email, purpose,
    createdAt: { $gt: new Date(Date.now() - 15 * 60 * 1000) }
  });
  if (recent >= 3) throw new AppError('Too many requests. Wait 15 min.', 429);

  const otp = await OTP.createOTP(email, purpose);
  logger.info(`OTP [${purpose}] for ${email}: ${otp}`);

  try {
    await sendOTP(email, otp, purpose);
  } catch (err) {
    logger.warn(`Email failed: ${err.message}`);
    if (process.env.NODE_ENV === 'development') {
      return ApiResponse.success(res, 200, `OTP: ${otp} (dev mode)`);
    }
  }

  return ApiResponse.success(res, 200, 'OTP sent to email');
}));

// POST /api/otp/verify
router.post('/verify', validateOTP, catchAsync(async (req, res) => {
  const { email, otp, purpose } = req.body;

  const result = await OTP.verifyOTP(email, otp, purpose || 'email_verification');
  if (!result.valid) throw new AppError(result.message, 400);

  if (purpose === 'email_verification') {
    await Employee.findOneAndUpdate({ email }, { isEmailVerified: true });
  }

  if (purpose === 'login') {
    const employee = await Employee.findOne({ email });
    if (!employee) throw new NotFoundError('Employee');
    if (!employee.isActive) throw new AppError('Account deactivated', 401);

    const token = employee.getSignedJwtToken();
    logger.info(`OTP login: ${employee.employeeId}`);

    return ApiResponse.success(res, 200, 'OTP verified', {
      verified: true, token,
      employee: {
        id: employee._id, employeeId: employee.employeeId,
        firstName: employee.firstName, lastName: employee.lastName,
        email: employee.email, department: employee.department
      }
    });
  }

  return ApiResponse.success(res, 200, result.message, { verified: true });
}));

module.exports = router;
