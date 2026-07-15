const { body, param, query, validationResult } = require('express-validator');

// Handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map(err => ({
        field: err.path,
        message: err.msg,
        value: err.value
      }))
    });
  }
  next();
};

// Signup Validation
const validateSignup = [
  body('firstName').trim().notEmpty().withMessage('First name required')
    .isLength({ min: 2, max: 50 }).withMessage('First name must be 2-50 characters')
    .matches(/^[a-zA-Z\s'-]+$/).withMessage('First name can only contain letters'),
  
  body('lastName').trim().notEmpty().withMessage('Last name required')
    .isLength({ min: 2, max: 50 }).withMessage('Last name must be 2-50 characters')
    .matches(/^[a-zA-Z\s'-]+$/).withMessage('Last name can only contain letters'),
  
  body('email').trim().notEmpty().withMessage('Email required')
    .isEmail().withMessage('Invalid email format').normalizeEmail(),
  
  body('phone').trim().notEmpty().withMessage('Phone required')
    .matches(/^[6-9]\d{9}$/).withMessage('Invalid Indian mobile number'),
  
  body('dateOfBirth').notEmpty().withMessage('Date of birth required')
    .isISO8601().withMessage('Invalid date format')
    .custom(value => {
      const age = new Date().getFullYear() - new Date(value).getFullYear();
      if (age < 18) throw new Error('Must be at least 18 years old');
      return true;
    }),
  
  body('gender').notEmpty().withMessage('Gender required')
    .isIn(['Male', 'Female', 'Other', 'Prefer not to say']).withMessage('Invalid gender'),
  
  body('password').notEmpty().withMessage('Password required')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).withMessage('Password must contain uppercase, lowercase and number'),
  
  body('department').notEmpty().withMessage('Department required')
    .isIn(['Engineering', 'Human Resources', 'Finance', 'Marketing', 'Sales', 'Operations', 'Customer Support', 'Design', 'Product', 'Legal', 'Administration', 'IT', 'Research', 'Other']),
  
  body('designation').trim().notEmpty().withMessage('Designation required'),
  
  body('dateOfJoining').notEmpty().withMessage('Joining date required').isISO8601(),
  
  body('employmentType').notEmpty().withMessage('Employment type required')
    .isIn(['Full-time', 'Part-time', 'Contract', 'Intern', 'Freelance']),
  
  handleValidationErrors
];

// Login Validation
const validateLogin = [
  body('email').trim().notEmpty().withMessage('Email required').isEmail().withMessage('Invalid email').normalizeEmail(),
  body('password').notEmpty().withMessage('Password required'),
  handleValidationErrors
];

// OTP Validation
const validateOTP = [
  body('email').trim().notEmpty().withMessage('Email required').isEmail().withMessage('Invalid email').normalizeEmail(),
  body('otp').trim().notEmpty().withMessage('OTP required')
    .isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits')
    .isNumeric().withMessage('OTP must be numbers only'),
  body('verificationToken').trim().notEmpty().withMessage('Verification token required')
    .isHexadecimal().withMessage('Invalid verification token')
    .isLength({ min: 64, max: 64 }).withMessage('Invalid verification token'),
  handleValidationErrors
];

// Email Validation
const validateEmail = [
  body('email').trim().notEmpty().withMessage('Email required').isEmail().withMessage('Invalid email').normalizeEmail(),
  handleValidationErrors
];

// Update Profile Validation
const validateUpdateProfile = [
  body('firstName').optional().trim().isLength({ max: 50 }),
  body('lastName').optional().trim().isLength({ max: 50 }),
  body('phone').optional().trim().matches(/^[6-9]\d{9}$/).withMessage('Invalid phone'),
  body('profilePhoto').optional().isString().isLength({ max: 8 * 1024 * 1024 })
    .matches(/^data:image\/(jpeg|jpg|png|webp);base64,/i).withMessage('Invalid profile photo'),
  handleValidationErrors
];

// Password Change Validation
const validatePasswordChange = [
  body('currentPassword').notEmpty().withMessage('Current password required'),
  body('newPassword').notEmpty().withMessage('New password required')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).withMessage('Must contain uppercase, lowercase and number'),
  handleValidationErrors
];

// Leave Validation
const validateLeave = [
  body('leaveType').notEmpty().withMessage('Leave type required')
    .isIn(['casual', 'sick', 'earned', 'maternity', 'paternity', 'compOff', 'unpaid']),
  body('startDate').notEmpty().withMessage('Start date required').isISO8601(),
  body('endDate').notEmpty().withMessage('End date required').isISO8601(),
  body('reason').trim().notEmpty().withMessage('Reason required')
    .isLength({ min: 5, max: 500 }).withMessage('Reason must be 5-500 characters'),
  handleValidationErrors
];

// Leave Approval Validation
const validateLeaveApproval = [
  param('leaveId').notEmpty().withMessage('Leave ID required').isMongoId().withMessage('Invalid Leave ID'),
  body('status').notEmpty().withMessage('Status required').isIn(['approved', 'rejected']),
  handleValidationErrors
];

// MongoDB ID Validation
const validateObjectId = [
  param('id').notEmpty().withMessage('ID required').isMongoId().withMessage('Invalid ID format'),
  handleValidationErrors
];

module.exports = {
  handleValidationErrors,
  validateSignup,
  validateLogin,
  validateOTP,
  validateEmail,
  validateUpdateProfile,
  validatePasswordChange,
  validateLeave,
  validateLeaveApproval,
  validateObjectId
};
