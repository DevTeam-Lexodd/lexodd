const mongoose = require('mongoose');
const crypto = require('crypto');

const otpSchema = new mongoose.Schema({
  email: { type: String, required: true, lowercase: true, trim: true },
  otpHash: { type: String, required: true, select: false },
  verificationTokenHash: { type: String, required: true, select: false },
  purpose: { type: String, enum: ['email_verification', 'password_reset', 'login'], required: true },
  attempts: { type: Number, default: 0, max: 5 },
  isUsed: { type: Boolean, default: false },
  expiresAt: { type: Date, required: true, index: { expires: '0s' } }
}, { timestamps: true });

otpSchema.index({ email: 1, purpose: 1 });
otpSchema.index({ email: 1, purpose: 1, createdAt: -1 });

// OTP validity window in minutes - parses OTP_EXPIRY safely
otpSchema.statics.expiryMinutes = function() {
  const parsed = parseInt(process.env.OTP_EXPIRY, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 5;
};

otpSchema.statics.generateOTP = function() {
  return crypto.randomInt(100000, 999999).toString();
};

otpSchema.statics.generateVerificationToken = function() {
  return crypto.randomBytes(32).toString('hex');
};

otpSchema.statics.hashValue = function(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
};

// timingSafeEqual throws on unequal-length buffers - compare safely instead
otpSchema.statics.safeEqual = function(hexA, hexB) {
  const a = Buffer.from(hexA, 'hex');
  const b = Buffer.from(hexB, 'hex');
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
};

// Count OTPs issued for rate limiting (old OTPs are superseded, not deleted,
// so this count reflects real send volume within the window).
otpSchema.statics.countRecent = function(email, purpose, windowMs) {
  return this.countDocuments({
    email,
    purpose,
    createdAt: { $gt: new Date(Date.now() - windowMs) }
  });
};

// Most recent OTP issued at (for resend cooldown checks)
otpSchema.statics.getLastIssuedAt = async function(email, purpose) {
  const latest = await this.findOne({ email, purpose }).sort({ createdAt: -1 }).select('createdAt');
  return latest ? latest.createdAt : null;
};

otpSchema.statics.createOTP = async function(email, purpose) {
  // Supersede (don't delete) any outstanding OTPs so issue history stays
  // intact for rate limiting. Only isUsed:false docs are verify candidates.
  await this.updateMany({ email, purpose, isUsed: false }, { $set: { isUsed: true } });
  const otp = this.generateOTP();
  const verificationToken = this.generateVerificationToken();
  const doc = await this.create({
    email,
    otpHash: this.hashValue(otp),
    verificationTokenHash: this.hashValue(verificationToken),
    purpose,
    expiresAt: new Date(Date.now() + this.expiryMinutes() * 60 * 1000)
  });
  return { otp, verificationToken, id: doc._id };
};

otpSchema.statics.verifyOTP = async function(email, otp, purpose, verificationToken) {
  if (!otp || !verificationToken) {
    return { valid: false, message: 'OTP and verification token are required.' };
  }

  const otpDoc = await this.findOne({
    email, purpose, isUsed: false,
    expiresAt: { $gt: new Date() }
  }).select('+otpHash +verificationTokenHash').sort({ createdAt: -1 });

  if (!otpDoc) {
    return { valid: false, message: 'OTP expired or not found. Request a new one.' };
  }

  if (otpDoc.attempts >= 5) {
    otpDoc.isUsed = true;
    await otpDoc.save();
    return { valid: false, message: 'Max attempts exceeded. Request a new OTP.' };
  }

  const isOtpValid = this.safeEqual(otpDoc.otpHash, this.hashValue(otp));
  const isTokenValid = this.safeEqual(otpDoc.verificationTokenHash, this.hashValue(verificationToken));

  if (!isOtpValid || !isTokenValid) {
    otpDoc.attempts += 1;
    await otpDoc.save();
    return { valid: false, message: `Invalid OTP. ${5 - otpDoc.attempts} attempts remaining.` };
  }

  otpDoc.isUsed = true;
  await otpDoc.save();
  return { valid: true, message: 'OTP verified successfully.' };
};

module.exports = mongoose.model('OTP', otpSchema);
