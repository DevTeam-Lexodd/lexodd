const jwt = require('jsonwebtoken');
const { AppError, AuthenticationError, AuthorizationError } = require('./errorHandler');
const Employee = require('../models/Employee');

// Protect routes - Verify JWT
const protect = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return next(new AuthenticationError('Please login to access this route'));
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const employee = await Employee.findById(decoded.id).select('-password');
      
      if (!employee) {
        return next(new AuthenticationError('Employee no longer exists'));
      }

      if (!employee.isActive) {
        return next(new AuthenticationError('Account deactivated. Contact HR.'));
      }

      if (employee.passwordChangedAt) {
        const changedTimestamp = parseInt(employee.passwordChangedAt.getTime() / 1000, 10);
        if (decoded.iat < changedTimestamp) {
          return next(new AuthenticationError('Password recently changed. Please login again.'));
        }
      }

      req.employee = employee;
      next();
    } catch (error) {
      return next(new AuthenticationError('Invalid token. Please login again.'));
    }
  } catch (error) {
    next(error);
  }
};

// Authorize specific roles
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.employee.role)) {
      return next(new AuthorizationError(`Role '${req.employee.role}' cannot access this route`));
    }
    next();
  };
};

module.exports = { protect, authorize };
