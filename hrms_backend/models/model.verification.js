const mongoose = require("mongoose");

const verifiedEmailSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true
    },

    verified: {
      type: Boolean,
      default: true
    },

    expiresAt: {
      type: Date,
      default: () => new Date(Date.now() + 10 * 60 * 1000)
    }
  },
  {
    timestamps: true
  }
);

verifiedEmailSchema.index(
  { expiresAt: 1 },
  { expireAfterSeconds: 0 }
);

module.exports = mongoose.model(
  "VerifiedEmail",
  verifiedEmailSchema
);