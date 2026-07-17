const Employee = require('../models/Employee');
const email = require('../utils/email');
const logger = require('../utils/logger');

// Notifications must never fail the API request that triggered them.
// Failures are logged; the business action (signup / approval / leave) still succeeds.
const fireAndForget = (work, label) => {
  Promise.resolve()
    .then(work)
    .then((result) => {
      if (result && result.success === false) {
        logger.warn(`${label}: email not delivered (${result.reason || 'unknown'})`);
      }
    })
    .catch((err) => logger.warn(`${label}: ${err.message}`));
};

const getAdminEmails = async () => {
  const admins = await Employee.find({ role: 'admin', isActive: true }).select('email');
  return admins.map((a) => a.email).filter(Boolean);
};

// New signup awaiting approval -> notify all active admins
const notifyAdminsOfSignup = (employee) => {
  fireAndForget(async () => {
    const adminEmails = await getAdminEmails();
    if (!adminEmails.length) {
      logger.warn('Signup request notification: no active admin users to notify');
      return { success: true };
    }
    return email.sendSignupRequestToAdmins(adminEmails, employee);
  }, 'Signup request notification');
};

// Admin approved/rejected a registration -> notify the employee
const notifyEmployeeOfApproval = (employee, approved, rejectionReason) => {
  fireAndForget(
    () => email.sendSignupDecision(employee, approved, rejectionReason),
    'Signup decision notification'
  );
};

// New leave request -> notify all active admins
const notifyAdminsOfLeave = (leave, employee) => {
  fireAndForget(async () => {
    const adminEmails = await getAdminEmails();
    if (!adminEmails.length) {
      logger.warn('Leave request notification: no active admin users to notify');
      return { success: true };
    }
    return email.sendLeaveRequestToAdmins(adminEmails, leave, employee);
  }, 'Leave request notification');
};

// Leave approved/rejected -> notify the employee
const notifyEmployeeOfLeaveDecision = (leave, employee, approved, rejectionReason) => {
  fireAndForget(
    () => email.sendLeaveDecision(leave, employee, approved, rejectionReason),
    'Leave decision notification'
  );
};

module.exports = {
  notifyAdminsOfSignup,
  notifyEmployeeOfApproval,
  notifyAdminsOfLeave,
  notifyEmployeeOfLeaveDecision
};
