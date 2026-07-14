const logger = require('../utils/logger');

class AppError extends Error {
  constructor(message, statusCode, errorCode = null) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.errorCode = errorCode || `ERR_${statusCode}`;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

class NotFoundError extends AppError {
  constructor(resource = 'Resource') {
    super(`${resource} not found`, 404, 'ERR_NOT_FOUND');
  }
}

class AuthenticationError extends AppError {
  constructor(message = 'Invalid credentials') {
    super(message, 401, 'ERR_AUTH');
  }
}

class AuthorizationError extends AppError {
  constructor(message = 'Not authorized') {
    super(message, 403, 'ERR_FORBIDDEN');
  }
}

const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;
  error.statusCode = err.statusCode;

  logger.error(`${err.message}`, {
    stack: err.stack,
    method: req.method,
    url: req.originalUrl
  });

  // Mongoose CastError
  if (err.name === 'CastError') {
    error = new NotFoundError('Resource');
  }

  // Mongoose Duplicate Key
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    error = new AppError(`Duplicate value for ${field}`, 400, 'ERR_DUPLICATE');
  }

  // Mongoose Validation
  if (err.name === 'ValidationError') {
    const messages = Object.values(err.errors).map(val => val.message);
    error = new AppError(`Validation failed: ${messages.join('. ')}`, 400, 'ERR_VALIDATION');
  }

  // JWT Errors
  if (err.name === 'JsonWebTokenError') {
    error = new AuthenticationError('Invalid token. Please login again.');
  }
  if (err.name === 'TokenExpiredError') {
    error = new AuthenticationError('Token expired. Please login again.');
  }

  res.status(error.statusCode || 500).json({
    success: false,
    status: error.status || 'error',
    errorCode: error.errorCode || 'ERR_UNKNOWN',
    message: error.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

const catchAsync = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

module.exports = errorHandler;
module.exports.AppError = AppError;
module.exports.NotFoundError = NotFoundError;
module.exports.AuthenticationError = AuthenticationError;
module.exports.AuthorizationError = AuthorizationError;
module.exports.catchAsync = catchAsync;
