const mongoose = require('mongoose');

const leaveSchema = new mongoose.Schema({
  employee: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  leaveType: { 
    type: String, required: true,
    enum: ['casual', 'sick', 'earned', 'maternity', 'paternity', 'compOff', 'unpaid']
  },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  numberOfDays: { type: Number, required: true, min: 0.5 },
  isHalfDay: { type: Boolean, default: false },
  halfDayType: { type: String, enum: ['first_half', 'second_half', ''], default: '' },
  reason: { type: String, required: true, trim: true, maxlength: 500 },
  status: { type: String, enum: ['pending', 'approved', 'rejected', 'cancelled'], default: 'pending' },
  approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee' },
  approvalDate: Date,
  rejectionReason: { type: String, trim: true, maxlength: 500 }
}, { timestamps: true });

leaveSchema.pre('save', function(next) {
  if (this.endDate < this.startDate) return next(new Error('End date must be after start date'));
  if (this.isHalfDay) {
    this.numberOfDays = 0.5;
  } else {
    const diffTime = Math.abs(this.endDate - this.startDate);
    this.numberOfDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
  }
  next();
});

leaveSchema.index({ employee: 1, status: 1 });
leaveSchema.index({ startDate: 1, endDate: 1 });

module.exports = mongoose.model('Leave', leaveSchema);
