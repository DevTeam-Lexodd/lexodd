const express = require('express');
const router = express.Router();

const Employee = require('../models/Employee');
const Leave = require('../models/Leave');
const { notifyAdminsOfLeave, notifyEmployeeOfApproval, notifyEmployeeOfLeaveDecision } = require('../services/notificationService');
const ApiResponse = require('../utils/apiResponse');
const { protect, authorize } = require('../middleware/auth');
const { catchAsync, AppError, NotFoundError, AuthorizationError, ConflictError } = require('../middleware/errorHandler');
const { validateObjectId, validateLeave, validateLeaveApproval, validateApproval } = require('../middleware/validate');
const logger = require('../utils/logger');

// NOTE: static routes (/dashboard, /leaves, /approvals/pending) must stay
// above parameterized routes (/:id) so Express doesn't treat them as an ID.

// GET /api/employees
router.get('/', protect, authorize('hr', 'admin', 'manager'), catchAsync(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;

  let filter = { isActive: true };
  if (req.query.department) filter.department = req.query.department;
  if (req.query.employmentType) filter.employmentType = req.query.employmentType;
  if (req.query.approvalStatus && ['pending', 'approved', 'rejected'].includes(req.query.approvalStatus)) {
    filter.approvalStatus = req.query.approvalStatus;
  }

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
  const pendingApprovals = await Employee.countDocuments({ approvalStatus: 'pending', isActive: true });
  const recentJoinees = await Employee.find({ isActive: true })
    .select('firstName lastName employeeId department designation dateOfJoining')
    .sort({ dateOfJoining: -1 }).limit(5);

  return ApiResponse.success(res, 200, 'Dashboard', { totalEmployees, departmentStats, pendingLeaves, pendingApprovals, recentJoinees });
}));

// GET /api/employees/approvals/pending - registration requests waiting on an admin decision
router.get('/approvals/pending', protect, authorize('admin'), catchAsync(async (req, res) => {
  const employees = await Employee.find({ approvalStatus: 'pending', isActive: true })
    .select('firstName lastName email phone employeeId department designation dateOfJoining employmentType approvalStatus createdAt')
    .sort({ createdAt: -1 });

  return ApiResponse.success(res, 200, 'Pending registrations fetched', { employees, count: employees.length });
}));

// GET /api/employees/leaves - approval queue for administrators
router.get('/leaves', protect, authorize('admin'), catchAsync(async (req, res) => {
  const filter = {};
  if (req.query.status) {
    if (!['pending', 'approved', 'rejected', 'cancelled'].includes(req.query.status)) {
      throw new AppError('Invalid leave status filter', 400);
    }
    filter.status = req.query.status;
  }

  const leaves = await Leave.find(filter)
    .populate('employee', 'firstName lastName email employeeId department designation')
    .sort({ createdAt: -1 });

  return ApiResponse.success(res, 200, 'Leaves fetched', { leaves, count: leaves.length });
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

// PUT /api/employees/:id/approval - admin approves or rejects a registration
router.put('/:id/approval', protect, authorize('admin'), validateApproval, catchAsync(async (req, res) => {
  const { status, rejectionReason } = req.body;

  if (status === 'rejected' && (!rejectionReason || !rejectionReason.trim())) {
    throw new AppError('Rejection reason is required when rejecting a registration.', 400);
  }

  const employee = await Employee.findById(req.params.id);
  if (!employee) throw new NotFoundError('Employee');

  if (employee._id.toString() === req.employee._id.toString()) {
    throw new AppError('You cannot change the approval status of your own account.', 400);
  }

  if (employee.approvalStatus === status) {
    throw new ConflictError(`Registration is already ${status}.`);
  }

  employee.approvalStatus = status;
  employee.approvedBy = req.employee._id;
  employee.approvalDate = new Date();
  employee.rejectionReason = status === 'rejected' ? rejectionReason.trim() : undefined;
  await employee.save();

  logger.info(`Registration ${status}: ${employee.employeeId} by ${req.employee.employeeId}`);

  // Notify the employee of the decision (non-blocking)
  notifyEmployeeOfApproval(employee, status === 'approved', employee.rejectionReason);

  return ApiResponse.success(res, 200, `Registration ${status}.`, {
    employee: {
      id: employee._id,
      employeeId: employee.employeeId,
      firstName: employee.firstName,
      lastName: employee.lastName,
      email: employee.email,
      department: employee.department,
      approvalStatus: employee.approvalStatus,
      rejectionReason: employee.rejectionReason
    }
  });
}));

// PUT /api/employees/leaves/:leaveId/approve - approve or reject a leave request
router.put('/leaves/:leaveId/approve', protect, authorize('hr', 'admin', 'manager'), validateLeaveApproval, catchAsync(async (req, res) => {
  const { status, rejectionReason } = req.body;

  if (status === 'rejected' && (!rejectionReason || !rejectionReason.trim())) {
    throw new AppError('Rejection reason is required when rejecting a leave.', 400);
  }

  const leave = await Leave.findById(req.params.leaveId);
  if (!leave) throw new NotFoundError('Leave');
  if (leave.status !== 'pending') {
    throw new ConflictError(`Leave already ${leave.status}.`);
  }

  const emp = await Employee.findById(leave.employee);

  // Balance check happens at approval time - the request may pre-date other approvals
  if (status === 'approved' && emp && emp.leaveBalance[leave.leaveType] !== undefined) {
    if (emp.leaveBalance[leave.leaveType] < leave.numberOfDays) {
      throw new AppError(`Insufficient ${leave.leaveType} balance (${emp.leaveBalance[leave.leaveType]} days left). Reject instead.`, 400);
    }
  }

  leave.status = status;
  leave.approvedBy = req.employee._id;
  leave.approvalDate = new Date();
  if (status === 'rejected') leave.rejectionReason = rejectionReason.trim();
  await leave.save();

  if (status === 'approved' && emp && emp.leaveBalance[leave.leaveType] !== undefined) {
    emp.leaveBalance[leave.leaveType] -= leave.numberOfDays;
    await emp.save();
  }

  logger.info(`Leave ${status}: ${leave._id} by ${req.employee.employeeId}`);

  // Notify the employee of the decision (non-blocking)
  if (emp) notifyEmployeeOfLeaveDecision(leave, emp, status === 'approved', leave.rejectionReason);

  return ApiResponse.success(res, 200, `Leave ${status}`, { leave });
}));

// PUT /api/employees/:id
router.put('/:id', protect, validateObjectId, catchAsync(async (req, res) => {
  if (req.employee.role === 'employee' && req.employee._id.toString() !== req.params.id) {
    throw new AuthorizationError('Cannot update this profile');
  }

  const allowed = ['firstName', 'lastName', 'phone', 'address', 'emergencyContact', 'bankDetails'];
  const hrOnly = ['department', 'designation', 'employmentType', 'ctc', 'role', 'isActive', 'approvalStatus'];
  if (req.body.approvalStatus !== undefined && req.employee.role !== 'admin') {
    throw new AuthorizationError('Only an admin can change a user approval status');
  }

  const updates = {};
  allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
  if (['hr', 'admin'].includes(req.employee.role)) {
    hrOnly.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
  }

  // Keep the audit trail consistent when approval changes through the generic update
  if (updates.approvalStatus && ['approved', 'rejected'].includes(updates.approvalStatus)) {
    updates.approvedBy = req.employee._id;
    updates.approvalDate = new Date();
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

  // Let admins know a leave request is waiting for review (non-blocking)
  notifyAdminsOfLeave(leave, employee);

  return ApiResponse.success(res, 201, 'Leave submitted', { leave });
}));

module.exports = router;
