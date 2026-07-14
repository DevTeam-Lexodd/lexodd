const express = require('express');
const router = express.Router();

const Employee = require('../models/Employee');
const Leave = require('../models/Leave');
const { sendEmail } = require('../utils/email');
const ApiResponse = require('../utils/apiResponse');
const { protect, authorize } = require('../middleware/auth');
const { catchAsync, AppError, NotFoundError, AuthorizationError } = require('../middleware/errorHandler');
const { validateObjectId, validateLeave, validateLeaveApproval } = require('../middleware/validate');
const logger = require('../utils/logger');

// GET /api/employees
router.get('/', protect, authorize('hr', 'admin', 'manager'), catchAsync(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;

  let filter = { isActive: true };
  if (req.query.department) filter.department = req.query.department;
  if (req.query.employmentType) filter.employmentType = req.query.employmentType;

  if (req.query.search) {
    const s = new RegExp(req.query.search, 'i');
    filter.$or = [{ firstName: s }, { lastName: s }, { email: s }, { employeeId: s }];
  }

  const total = await Employee.countDocuments(filter);
  const employees = await Employee.find(filter).select('-password').sort({ createdAt: -1 }).skip(skip).limit(limit);

  return ApiResponse.paginated(res, 200, 'Employees fetched', employees, { page, limit, total });
}));

// GET /api/employees/dashboard
router.get('/dashboard', protect, catchAsync(async (req, res) => {
  const totalEmployees = await Employee.countDocuments({ isActive: true });
  const departmentStats = await Employee.aggregate([
    { $match: { isActive: true } },
    { $group: { _id: '$department', count: { $sum: 1 } } },
    { $sort: { count: -1 } }
  ]);
  const pendingLeaves = await Leave.countDocuments({ status: 'pending' });
  const recentJoinees = await Employee.find({ isActive: true })
    .select('firstName lastName employeeId department designation dateOfJoining')
    .sort({ dateOfJoining: -1 }).limit(5);

  return ApiResponse.success(res, 200, 'Dashboard', { totalEmployees, departmentStats, pendingLeaves, recentJoinees });
}));

// GET /api/employees/:id
router.get('/:id', protect, validateObjectId, catchAsync(async (req, res) => {
  const employee = await Employee.findById(req.params.id);
  if (!employee) throw new NotFoundError('Employee');
  if (req.employee.role === 'employee' && req.employee._id.toString() !== req.params.id) {
    throw new AuthorizationError('Cannot view this profile');
  }
  return ApiResponse.success(res, 200, 'Employee fetched', { employee });
}));

// PUT /api/employees/:id
router.put('/:id', protect, validateObjectId, catchAsync(async (req, res) => {
  if (req.employee.role === 'employee' && req.employee._id.toString() !== req.params.id) {
    throw new AuthorizationError('Cannot update this profile');
  }

  const allowed = ['firstName', 'lastName', 'phone', 'address', 'emergencyContact', 'bankDetails'];
  const hrOnly = ['department', 'designation', 'employmentType', 'ctc', 'role', 'isActive'];
  
  const updates = {};
  allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
  if (['hr', 'admin'].includes(req.employee.role)) {
    hrOnly.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
  }

  const employee = await Employee.findByIdAndUpdate(req.params.id, { $set: updates }, { new: true });
  if (!employee) throw new NotFoundError('Employee');

  logger.info(`Updated: ${employee.employeeId}`);
  return ApiResponse.success(res, 200, 'Updated', { employee });
}));

// DELETE /api/employees/:id
router.delete('/:id', protect, authorize('admin', 'hr'), validateObjectId, catchAsync(async (req, res) => {
  const employee = await Employee.findByIdAndUpdate(req.params.id, { isActive: false }, { new: true });
  if (!employee) throw new NotFoundError('Employee');
  return ApiResponse.success(res, 200, 'Deactivated');
}));

// GET /api/employees/:id/leaves
router.get('/:id/leaves', protect, validateObjectId, catchAsync(async (req, res) => {
  if (req.employee.role === 'employee' && req.employee._id.toString() !== req.params.id) {
    throw new AuthorizationError('Cannot view these leaves');
  }

  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;

  const filter = { employee: req.params.id };
  if (req.query.status) filter.status = req.query.status;

  const total = await Leave.countDocuments(filter);
  const leaves = await Leave.find(filter).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit);
  const employee = await Employee.findById(req.params.id).select('leaveBalance');

  return ApiResponse.paginated(res, 200, 'Leaves', { leaves, leaveBalance: employee?.leaveBalance }, { page, limit, total });
}));

// POST /api/employees/:id/leaves
router.post('/:id/leaves', protect, validateObjectId, validateLeave, catchAsync(async (req, res) => {
  if (req.employee._id.toString() !== req.params.id) {
    throw new AuthorizationError('Can only apply for yourself');
  }

  const { leaveType, startDate, endDate, reason, isHalfDay } = req.body;
  const employee = await Employee.findById(req.params.id);
  if (!employee) throw new NotFoundError('Employee');

  const start = new Date(startDate);
  const end = new Date(endDate);
  const days = isHalfDay ? 0.5 : Math.ceil((end - start) / 86400000) + 1;

  const balance = employee.leaveBalance[leaveType];
  if (balance !== undefined && balance < days) {
    throw new AppError(`Insufficient ${leaveType} leave. Available: ${balance}`, 400);
  }

  const leave = await Leave.create({
    employee: req.params.id, leaveType, startDate: start, endDate: end,
    numberOfDays: days, reason, isHalfDay: isHalfDay || false
  });

  logger.info(`Leave applied: ${employee.employeeId} - ${days} days`);
  return ApiResponse.success(res, 201, 'Leave submitted', { leave });
}));

// PUT /api/employees/leaves/:leaveId/approve
router.put('/leaves/:leaveId/approve', protect, authorize('hr', 'admin', 'manager'), validateLeaveApproval, catchAsync(async (req, res) => {
  const { status, rejectionReason } = req.body;

  const leave = await Leave.findById(req.params.leaveId);
  if (!leave) throw new NotFoundError('Leave');
  if (leave.status !== 'pending') throw new AppError(`Already ${leave.status}`, 400);

  leave.status = status;
  leave.approvedBy = req.employee._id;
  leave.approvalDate = new Date();
  if (status === 'rejected') leave.rejectionReason = rejectionReason;
  await leave.save();

  if (status === 'approved') {
    const emp = await Employee.findById(leave.employee);
    if (emp && emp.leaveBalance[leave.leaveType] !== undefined) {
      emp.leaveBalance[leave.leaveType] -= leave.numberOfDays;
      await emp.save();
    }
  }

  logger.info(`Leave ${status}: ${leave._id}`);
  return ApiResponse.success(res, 200, `Leave ${status}`, { leave });
}));

module.exports = router;
