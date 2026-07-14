const mongoose = require('mongoose');
const crypto = require('crypto');

const otpSchema = new mongoose.Schema({
  email: { type: String, required: true, lowercase: true, trim: true },
  otp: { type: String, required: true },
  purpose: { type: String, enum: ['email_verification', 'password_reset', 'login'], required: true },
  attempts: { type: Number, default: 0, max: 5 },
  isUsed: { type: Boolean, default: false },
  expiresAt: { type: Date, required: true, index: { expires: '0s' } }
}, { timestamps: true });

otpSchema.index({ email: 1, purpose: 1 });

otpSchema.statics.generateOTP = function() {
  return crypto.randomInt(100000, 999999).toString();
};

otpSchema.statics.createOTP = async function(email, purpose) {
  await this.deleteMany({ email, purpose });
  const otp = this.generateOTP();
  await this.create({
    email, otp, purpose,
    expiresAt: new Date(Date.now() + (process.env.OTP_EXPIRY || 5) * 60 * 1000)
  });
  return otp;
};

otpSchema.statics.verifyOTP = async function(email, otp, purpose) {
  const otpDoc = await this.findOne({
    email, purpose, isUsed: false,
    expiresAt: { $gt: new Date() }
  }).sort({ createdAt: -1 });

  if (!otpDoc) {
    return { valid: false, message: 'OTP expired or not found. Request a new one.' };
  }

  if (otpDoc.attempts >= 5) {
    await otpDoc.deleteOne();
    return { valid: false, message: 'Max attempts exceeded. Request a new OTP.' };
  }

  if (otpDoc.otp !== otp) {
    otpDoc.attempts += 1;
    await otpDoc.save();
    return { valid: false, message: `Invalid OTP. ${5 - otpDoc.attempts} attempts remaining.` };
  }

  otpDoc.isUsed = true;
  await otpDoc.save();
  return { valid: true, message: 'OTP verified successfully.' };
};

module.exports = mongoose.model('OTP', otpSchema);
