const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const employeeSchema = new mongoose.Schema({
  // Personal Info
  employeeId: { type: String, unique: true, sparse: true },
  firstName: { type: String, required: [true, 'First name required'], trim: true, maxlength: 50 },
  lastName: { type: String, required: [true, 'Last name required'], trim: true, maxlength: 50 },
  email: { 
    type: String, required: [true, 'Email required'], unique: true, lowercase: true, trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Invalid email']
  },
  phone: { type: String, required: [true, 'Phone required'], match: [/^[6-9]\d{9}$/, 'Invalid phone'] },
  alternatePhone: { type: String },
  dateOfBirth: { type: Date, required: [true, 'DOB required'] },
  gender: { type: String, required: true, enum: ['Male', 'Female', 'Other', 'Prefer not to say'] },
  bloodGroup: { type: String, enum: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', ''] },
  maritalStatus: { type: String, enum: ['Single', 'Married', 'Divorced', 'Widowed', ''] },
  profilePhoto: { type: String, default: '' },

  // Address
  address: {
    street: String, city: String, state: String,
    pincode: { type: String, match: [/^\d{6}$/, 'Invalid pincode'] },
    country: { type: String, default: 'India' }
  },
  permanentAddress: {
    street: String, city: String, state: String,
    pincode: String,
    country: { type: String, default: 'India' }
  },
  sameAsPermanent: { type: Boolean, default: false },

  // Employment
  department: {
    type: String, required: [true, 'Department required'],
    enum: ['Engineering', 'Human Resources', 'Finance', 'Marketing', 'Sales', 'Operations', 'Customer Support', 'Design', 'Product', 'Legal', 'Administration', 'IT', 'Research', 'Other']
  },
  designation: { type: String, required: [true, 'Designation required'], trim: true },
  dateOfJoining: { type: Date, required: [true, 'Joining date required'] },
  employmentType: { type: String, required: true, enum: ['Full-time', 'Part-time', 'Contract', 'Intern', 'Freelance'] },
  workLocation: { type: String, enum: ['Office', 'Remote', 'Hybrid'], default: 'Office' },
  reportingManager: { type: String, trim: true },
  ctc: { type: Number, min: 0 },

  // Emergency Contact
  emergencyContact: {
    name: String,
    relationship: String,
    phone: String
  },

  // Bank Details
  bankDetails: {
    accountNumber: String,
    bankName: String,
    branchName: String,
    ifscCode: { type: String, uppercase: true },
    accountType: { type: String, enum: ['Savings', 'Current', ''] }
  },

  // Documents
  documents: {
    aadharNumber: String,
    panNumber: { type: String, uppercase: true },
    passportNumber: String,
    drivingLicense: String
  },

  // Education
  education: [{
    degree: String,
    institution: String,
    university: String,
    yearOfPassing: Number,
    percentage: Number
  }],

  // Leave Balance
  leaveBalance: {
    casual: { type: Number, default: 12 },
    sick: { type: Number, default: 12 },
    earned: { type: Number, default: 15 },
    maternity: { type: Number, default: 0 },
    paternity: { type: Number, default: 0 },
    compOff: { type: Number, default: 0 }
  },

  // Auth
  password: { type: String, required: true, minlength: 8, select: false },
  role: { type: String, enum: ['employee', 'manager', 'hr', 'admin'], default: 'employee' },
  isEmailVerified: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },
  passwordChangedAt: Date,
  lastLogin: Date,
  loginAttempts: { type: Number, default: 0 },
  lockUntil: Date

}, { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } });

// Virtuals
employeeSchema.virtual('fullName').get(function() {
  return `${this.firstName} ${this.lastName}`;
});

employeeSchema.virtual('age').get(function() {
  if (!this.dateOfBirth) return null;
  const today = new Date();
  const birth = new Date(this.dateOfBirth);
  let age = today.getFullYear() - birth.getFullYear();
  if (today.getMonth() < birth.getMonth() || (today.getMonth() === birth.getMonth() && today.getDate() < birth.getDate())) age--;
  return age;
});

employeeSchema.virtual('tenure').get(function() {
  if (!this.dateOfJoining) return 'N/A';
  const months = (new Date().getFullYear() - this.dateOfJoining.getFullYear()) * 12 + (new Date().getMonth() - this.dateOfJoining.getMonth());
  const years = Math.floor(months / 12);
  const rem = months % 12;
  return years > 0 ? `${years} yr ${rem} mo` : `${rem} months`;
});

employeeSchema.virtual('isLocked').get(function() {
  return !!(this.lockUntil && this.lockUntil > Date.now());
});

// Hash password before save
employeeSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

// Generate employee ID
employeeSchema.pre('save', async function(next) {
  if (this.employeeId) return next();
  const count = await mongoose.model('Employee').countDocuments();
  const year = new Date().getFullYear().toString().slice(-2);
  const month = (new Date().getMonth() + 1).toString().padStart(2, '0');
  this.employeeId = `EMP${year}${month}${(count + 1).toString().padStart(4, '0')}`;
  next();
});

// Update passwordChangedAt
employeeSchema.pre('save', function(next) {
  if (!this.isModified('password') || this.isNew) return next();
  this.passwordChangedAt = Date.now() - 1000;
  next();
});

// Methods
employeeSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

employeeSchema.methods.getSignedJwtToken = function() {
  return jwt.sign(
    { id: this._id, role: this.role, email: this.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE }
  );
};

employeeSchema.methods.incrementLoginAttempts = async function() {
  if (this.lockUntil && this.lockUntil < Date.now()) {
    return await this.updateOne({ $set: { loginAttempts: 1 }, $unset: { lockUntil: 1 } });
  }
  const updates = { $inc: { loginAttempts: 1 } };
  if (this.loginAttempts + 1 >= 5 && !this.isLocked) {
    updates.$set = { lockUntil: Date.now() + 30 * 60 * 1000 };
  }
  return await this.updateOne(updates);
};

employeeSchema.methods.resetLoginAttempts = async function() {
  return await this.updateOne({
    $set: { loginAttempts: 0, lastLogin: new Date() },
    $unset: { lockUntil: 1 }
  });
};

module.exports = mongoose.model('Employee', employeeSchema);
