const OTP = require('../models/OTP');
const Employee = require('../models/Employee');
const PendingSignup = require('../models/PendingSignup');
const { sendOTP } = require('../utils/email');
const { AppError, ConflictError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

const VALID_PURPOSES = ['email_verification', 'login', 'password_reset'];

// Send limits
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 minutes
const RATE_LIMIT_MAX = 3;                    // max OTPs per email+purpose per window
const RESEND_COOLDOWN_MS = 60 * 1000;        // 60 seconds between sends

// After OTP verification the user has this long to complete the signup form
const PENDING_SIGNUP_TTL_MS = 10 * 60 * 1000;

// Map a Graph/email send failure to an HTTP error
const emailFailureError = (reason) => {
  if (reason === 'EMAIL_NOT_CONFIGURED' || reason === 'GRAPH_AUTH_ERROR') {
    return new AppError('Email service is not configured. Please try again later.', 503, 'ERR_EMAIL_NOT_CONFIGURED');
  }
  if (reason === 'TIMEOUT') {
    return new AppError('Email service timed out. Please try again.', 504, 'ERR_EMAIL_TIMEOUT');
  }
  return new AppError('Unable to send OTP email. Please try again later.', 502, 'ERR_EMAIL_DELIVERY');
};

/**
 * Validate purpose and check account existence rules:
 *  - email_verification (signup): the email must NOT be registered already
 *  - login / password_reset: the email MUST belong to an existing account
 */
const assertPurposeAllowed = async (email, purpose) => {
  if (!VALID_PURPOSES.includes(purpose)) {
    throw new AppError(`Invalid purpose. Must be one of: ${VALID_PURPOSES.join(', ')}`, 400);
  }

  const employee = await Employee.findOne({ email });

  if (purpose === 'email_verification' && employee) {
    throw new ConflictError('Email already registered. Please login.');
  }

  if ((purpose === 'login' || purpose === 'password_reset') && !employee) {
    throw new AppError('No account found with this email.', 404, 'ERR_NOT_FOUND');
  }

  return employee;
};

/**
 * Issue a new OTP and deliver it via Microsoft Graph email.
 * Throws on any failure; on email delivery failure the OTP row is removed
 * so users can never "verify" an OTP they never received.
 */
const requestOTP = async ({ email, purpose }) => {
  await assertPurposeAllowed(email, purpose);

  // Resend cooldown: one OTP per minute per email+purpose
  const lastIssuedAt = await OTP.getLastIssuedAt(email, purpose);
  if (lastIssuedAt && Date.now() - lastIssuedAt.getTime() < RESEND_COOLDOWN_MS) {
    const waitSeconds = Math.ceil((RESEND_COOLDOWN_MS - (Date.now() - lastIssuedAt.getTime())) / 1000);
    throw new AppError(`Please wait ${waitSeconds}s before requesting a new OTP.`, 429, 'ERR_OTP_COOLDOWN');
  }

  // Rate limit: max OTPs per window per email+purpose
  const recent = await OTP.countRecent(email, purpose, RATE_LIMIT_WINDOW_MS);
  if (recent >= RATE_LIMIT_MAX) {
    throw new AppError('Too many OTP requests. Please try again in 15 minutes.', 429, 'ERR_OTP_RATE_LIMIT');
  }

  const { otp, verificationToken, id } = await OTP.createOTP(email, purpose);

  const emailResult = await sendOTP(email, otp, purpose);
  if (!emailResult.success) {
    // Roll back the OTP so it cannot be validated without being delivered
    await OTP.deleteOne({ _id: id }).catch((err) =>
      logger.warn(`OTP cleanup failed for ${email}: ${err.message}`));
    logger.warn(`OTP email not delivered to ${email}: ${emailResult.reason}`);
    throw emailFailureError(emailResult.reason);
  }

  logger.info(`OTP sent: ${email} (${purpose})`);
  return { verificationToken };
};

/**
 * Verify an OTP. On success for email_verification, a PendingSignup record
 * grants 10 minutes to complete registration with the same verificationToken.
 * Returns { verified: true } - route layers add purpose-specific responses.
 */
const verifyOTP = async ({ email, otp, purpose, verificationToken }) => {
  if (!VALID_PURPOSES.includes(purpose)) {
    throw new AppError(`Invalid purpose. Must be one of: ${VALID_PURPOSES.join(', ')}`, 400);
  }

  const result = await OTP.verifyOTP(email, otp, purpose, verificationToken);
  if (!result.valid) {
    throw new AppError(result.message, 400, 'ERR_OTP_INVALID');
  }

  if (purpose === 'email_verification') {
    const verificationTokenHash = PendingSignup.hashValue(verificationToken);
    await PendingSignup.findOneAndUpdate(
      { verificationTokenHash },
      {
        email,
        data: { emailVerified: true },
        expiresAt: new Date(Date.now() + PENDING_SIGNUP_TTL_MS)
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
  }

  return { verified: true };
};

/**
 * Assert that a signup request carries a valid, recently verified email token.
 * Returns the PendingSignup doc for cleanup after successful registration.
 */
const assertVerifiedSignup = async (email, verificationToken) => {
  if (!verificationToken) {
    throw new AppError('Verify your email before completing registration.', 400, 'ERR_EMAIL_NOT_VERIFIED');
  }
  const verificationTokenHash = PendingSignup.hashValue(verificationToken);
  const pending = await PendingSignup.findOne({ verificationTokenHash }).select('+verificationTokenHash');
  if (!pending || pending.email !== email) {
    throw new AppError('Email verification expired. Please verify your email again.', 400, 'ERR_EMAIL_NOT_VERIFIED');
  }
  return pending;
};

module.exports = {
  VALID_PURPOSES,
  requestOTP,
  verifyOTP,
  assertVerifiedSignup
};
