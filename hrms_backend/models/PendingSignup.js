const mongoose = require('mongoose');

const pendingSignupSchema = new mongoose.Schema({
  verificationTokenHash: { type: String, required: true, unique: true, select: false },
  data: { type: mongoose.Schema.Types.Mixed, required: true },
  email: { type: String, required: true, lowercase: true, trim: true },
  expiresAt: { type: Date, required: true, index: { expires: '0s' } }
}, { timestamps: true });

pendingSignupSchema.index({ email: 1 });

const crypto = require('crypto');

pendingSignupSchema.statics.hashValue = function(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
};

pendingSignupSchema.statics.safeEqual = function(hexA, hexB) {
  const a = Buffer.from(hexA, 'hex');
  const b = Buffer.from(hexB, 'hex');
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
};

module.exports = mongoose.model('PendingSignup', pendingSignupSchema);