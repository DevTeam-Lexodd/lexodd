const { ClientSecretCredential } = require('@azure/identity');

const graphScope = 'https://graph.microsoft.com/.default';
const requiredEmailEnv = ['AZURE_TENANT_ID', 'AZURE_CLIENT_ID', 'AZURE_CLIENT_SECRET', 'EMAIL_USER'];
let credential;

function getCredential() {
  const missing = requiredEmailEnv.filter((key) => !process.env[key]);
  if (missing.length) {
    const error = new Error(`Microsoft Graph email is not configured: ${missing.join(', ')}`);
    error.code = 'EMAIL_NOT_CONFIGURED';
    throw error;
  }
  if (!credential) {
    credential = new ClientSecretCredential(
      process.env.AZURE_TENANT_ID,
      process.env.AZURE_CLIENT_ID,
      process.env.AZURE_CLIENT_SECRET,
      process.env.EMAIL_USER
    );
  }
  return credential;
}

// OTP validity window in minutes - must match models/OTP.js
function otpExpiryMinutes() {
  const parsed = parseInt(process.env.OTP_EXPIRY, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 5;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function layout(title, bodyHtml) {
  return `<div style="font-family:Arial,sans-serif;color:#1f2937;max-width:560px;margin:auto">` +
    `<h2 style="margin-bottom:4px">Lexodd HRMS</h2>` +
    `<h3 style="margin-top:0;color:#4f46e5">${title}</h3>` +
    bodyHtml +
    `<p style="color:#6b7280;font-size:12px;margin-top:24px">This is an automated message from Lexodd HRMS. Please do not reply.</p>` +
    `</div>`;
}

function otpEmail(otp, purpose) {
  const labels = {
    email_verification: 'verify your email address',
    login: 'sign in to your account',
    password_reset: 'reset your password'
  };
  const action = labels[purpose] || 'complete your request';
  const expiry = otpExpiryMinutes();
  return {
    subject: `Lexodd verification code: ${otp}`,
    html: layout('Your verification code',
      `<p>Use the code below to ${action}.</p>` +
      `<p style="font-size:28px;font-weight:700;letter-spacing:6px">${otp}</p>` +
      `<p>This code expires in ${expiry} minute${expiry === 1 ? '' : 's'}. If you did not request it, you can safely ignore this email.</p>`)
  };
}

function signupRequestEmail(employee) {
  const name = escapeHtml(`${employee.firstName} ${employee.lastName}`);
  return {
    subject: `New registration pending approval: ${employee.employeeId || ''}`.trim(),
    html: layout('New registration request',
      `<p>A new employee has registered and is waiting for your approval.</p>` +
      `<table style="border-collapse:collapse">` +
      `<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Name</td><td>${name}</td></tr>` +
      `<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Email</td><td>${escapeHtml(employee.email)}</td></tr>` +
      `<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Employee ID</td><td>${escapeHtml(employee.employeeId || '-')}</td></tr>` +
      `<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Department</td><td>${escapeHtml(employee.department || '-')}</td></tr>` +
      `<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Designation</td><td>${escapeHtml(employee.designation || '-')}</td></tr>` +
      `</table>` +
      `<p>Open the Admin approvals panel in the Lexodd app to approve or reject this registration.</p>`)
  };
}

function signupDecisionEmail(employee, approved, rejectionReason) {
  const name = escapeHtml(employee.firstName);
  if (approved) {
    return {
      subject: 'Your Lexodd account has been approved',
      html: layout('Registration approved',
        `<p>Hi ${name},</p>` +
        `<p>Good news - your Lexodd HRMS registration has been <strong>approved</strong>. You can now sign in and use the app.</p>`)
    };
  }
  return {
    subject: 'Your Lexodd registration was not approved',
    html: layout('Registration rejected',
      `<p>Hi ${name},</p>` +
      `<p>Your Lexodd HRMS registration was <strong>rejected</strong>.</p>` +
      (rejectionReason ? `<p><strong>Reason:</strong> ${escapeHtml(rejectionReason)}</p>` : '') +
      `<p>If you believe this is a mistake, please contact your HR team.</p>`)
  };
}

function formatDate(value) {
  if (!value) return '-';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '-' : date.toDateString();
}

function leaveRequestEmail(leave, employee) {
  const name = escapeHtml(`${employee.firstName} ${employee.lastName}`);
  return {
    subject: `Leave request from ${employee.firstName} ${employee.lastName}`,
    html: layout('New leave request',
      `<p>A leave request is waiting for your review.</p>` +
      `<table style="border-collapse:collapse">` +
      `<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Employee</td><td>${name} (${escapeHtml(employee.employeeId || '-')})</td></tr>` +
      `<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Type</td><td>${escapeHtml(leave.leaveType)}</td></tr>` +
      `<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Dates</td><td>${formatDate(leave.startDate)} to ${formatDate(leave.endDate)}</td></tr>` +
      `<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Days</td><td>${leave.numberOfDays}</td></tr>` +
      `<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Reason</td><td>${escapeHtml(leave.reason || '-')}</td></tr>` +
      `</table>` +
      `<p>Open the Admin approvals panel in the Lexodd app to approve or reject this request.</p>`)
  };
}

function leaveDecisionEmail(leave, employee, approved, rejectionReason) {
  const name = escapeHtml(employee.firstName);
  const decision = approved ? 'approved' : 'rejected';
  return {
    subject: `Your ${leave.leaveType} leave was ${decision}`,
    html: layout(`Leave ${decision}`,
      `<p>Hi ${name},</p>` +
      `<p>Your <strong>${escapeHtml(leave.leaveType)}</strong> leave from <strong>${formatDate(leave.startDate)}</strong> to <strong>${formatDate(leave.endDate)}</strong> (${leave.numberOfDays} day${leave.numberOfDays === 1 ? '' : 's'}) has been <strong>${decision}</strong>.</p>` +
      (!approved && rejectionReason ? `<p><strong>Reason:</strong> ${escapeHtml(rejectionReason)}</p>` : ''))
  };
}

async function sendEmail({ to, subject, html }) {
  const recipient = typeof to === 'string' ? to : to?.email;
  if (!recipient) return { success: false, reason: 'MISSING_RECIPIENT' };
  try {
    const token = await getCredential().getToken(graphScope);
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    try {
      const response = await fetch(
        `https://graph.microsoft.com/v1.0/users/${encodeURIComponent(process.env.EMAIL_USER)}/sendMail`,
        {
          method: 'POST',
          headers: { Authorization: `Bearer ${token.token}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            message: {
              subject,
              body: { contentType: 'HTML', content: html },
              toRecipients: [{ emailAddress: { address: recipient } }]
            },
            saveToSentItems: true
          }),
          signal: controller.signal
        }
      );
      if (!response.ok) {
        const details = await response.text();
        console.error(`Microsoft Graph sendMail failed (${response.status}):`, details);
        return { success: false, reason: `GRAPH_ERROR_${response.status}`, details };
      }
      return { success: true };
    } finally {
      clearTimeout(timeout);
    }
  } catch (error) {
    const isTimeout = error.name === 'AbortError';
    console.error('Microsoft Graph email failed:', error.message);
    return { success: false, reason: isTimeout ? 'TIMEOUT' : error.code || 'GRAPH_AUTH_ERROR', details: error.message };
  }
}

async function sendOTP(to, otp, purpose = 'email_verification') {
  const { subject, html } = otpEmail(otp, purpose);
  return sendEmail({ to, subject, html });
}

async function sendSignupRequestToAdmins(adminEmails, employee) {
  const { subject, html } = signupRequestEmail(employee);
  const results = [];
  for (const adminEmail of adminEmails) {
    // Sequential sends keep us well under Graph throttling limits
    results.push(await sendEmail({ to: adminEmail, subject, html }));
  }
  return results.every((r) => r.success) ? { success: true } : { success: false, reason: 'PARTIAL_FAILURE', results };
}

async function sendSignupDecision(employee, approved, rejectionReason) {
  const { subject, html } = signupDecisionEmail(employee, approved, rejectionReason);
  return sendEmail({ to: employee.email, subject, html });
}

async function sendLeaveRequestToAdmins(adminEmails, leave, employee) {
  const { subject, html } = leaveRequestEmail(leave, employee);
  const results = [];
  for (const adminEmail of adminEmails) {
    results.push(await sendEmail({ to: adminEmail, subject, html }));
  }
  return results.every((r) => r.success) ? { success: true } : { success: false, reason: 'PARTIAL_FAILURE', results };
}

async function sendLeaveDecision(leave, employee, approved, rejectionReason) {
  const { subject, html } = leaveDecisionEmail(leave, employee, approved, rejectionReason);
  return sendEmail({ to: employee.email, subject, html });
}

module.exports = {
  sendEmail,
  sendOTP,
  sendSignupRequestToAdmins,
  sendSignupDecision,
  sendLeaveRequestToAdmins,
  sendLeaveDecision
};
