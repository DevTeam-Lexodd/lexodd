const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const logger = require('./utils/logger');
const errorHandler = require('./middleware/errorHandler');

// Fail fast on missing critical configuration
const requiredEnv = ['MONGODB_URI', 'JWT_SECRET'];
const missingEnv = requiredEnv.filter(key => !process.env[key]);
if (missingEnv.length > 0) {
  console.error(`FATAL: Missing required environment variables: ${missingEnv.join(', ')}`);
  console.error('See .env.example for the full list of configuration options.');
  process.exit(1);
}
['BREVO_API_KEY', 'BREVO_SENDER_EMAIL'].forEach(key => {
  if (!process.env[key]) console.warn(`WARN: ${key} not set - OTP emails will fail until it is configured.`);
});

// Import Routes
const authRoutes = require('./routes/auth.routes');
const employeeRoutes = require('./routes/employee.routes');
const otpRoutes = require('./routes/otp.routes');

const app = express();

// CORS
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.options('*', cors());

// Security
if (process.env.NODE_ENV === 'production') {
  app.use(helmet());
} else {
  app.use(helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: false
  }));
}

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  message: { success: false, message: 'Too many requests' }
});
app.use('/api/', limiter);

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Logging
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// Routes

app.get("/",(req,res)=>{
  res.send("Welcome to lexodd API");
})

app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'lexodd API running',
    environment: process.env.NODE_ENV,
    version: require('./package.json').version,
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

app.get('/api', (req, res) => {
  res.json({
    success: true,
    message: 'lexodd Hypernova System API v2.0',
    endpoints: {
      auth: 'POST /api/auth/signup, POST /api/auth/login, GET /api/auth/me',
      employees: 'GET /api/employees, GET /api/employees/dashboard',
      leaves: 'POST /api/employees/:id/leaves',
      otp: 'POST /api/otp/send, POST /api/otp/verify'
    }
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/otp', otpRoutes);

// 404
app.all('*', (req, res) => {
  res.status(404).json({ success: false, message: `Route not found: ${req.method} ${req.originalUrl}` });
});

// Error handler
app.use(errorHandler);

// Database
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    console.log(`Database: ${conn.connection.name}`);
  } catch (error) {
    console.error(`DB Error: ${error.message}`);
    process.exit(1);
  }
};

// Start
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();

  app.listen(PORT, '0.0.0.0', () => {
    console.log('');
    console.log('================================================');
    console.log('  lexodd Hypernova System API');
    console.log('================================================');
    console.log(`  Server: http://localhost:${PORT}`);
    console.log(`  Health: http://localhost:${PORT}/api/health`);
    console.log('================================================');
    console.log('');
  });
};

// Root route
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to lexodd API',
    docs: '/api',
    health: '/api/health'
  });
});

startServer();

module.exports = app;