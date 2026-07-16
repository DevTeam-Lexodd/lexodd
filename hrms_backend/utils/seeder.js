const mongoose = require('mongoose');
require('dotenv').config();

const Employee = require('../models/Employee');
const logger = require('./logger');

const seedAdmin = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    logger.info('Connected to MongoDB');

    const existing = await Employee.findOne({ role: 'admin' });
    if (existing) {
      logger.info('Admin already exists. Skipping.');
      logger.info(`Email: ${existing.email}`);
      process.exit(0);
    }

    const admin = await Employee.create({
      firstName: 'System',
      lastName: 'Admin',
      email: 'admin@company.com',
      phone: '9876543210',
      dateOfBirth: new Date('1990-01-15'),
      gender: 'Male',
      department: 'Administration',
      designation: 'System Administrator',
      dateOfJoining: new Date('2024-01-01'),
      employmentType: 'Full-time',
      password: 'Admin@123456',
      role: 'admin',
      isEmailVerified: true,
      address: {
        street: '123 Admin Street',
        city: 'Hyderabad',
        state: 'Telangana',
        pincode: '500001',
        country: 'India'
      }
    });

    logger.info('=================================');
    logger.info('Admin Created Successfully!');
    logger.info('=================================');
    logger.info(`Employee ID: ${admin.employeeId}`);
    logger.info(`Name: ${admin.fullName}`);
    logger.info('Email: admin@company.com');
    logger.info('Password: Admin@123456');
    logger.info('=================================');

    process.exit(0);
  } catch (error) {
    logger.error(`Seed error: ${error.message}`);
    process.exit(1);
  }
};

seedAdmin();