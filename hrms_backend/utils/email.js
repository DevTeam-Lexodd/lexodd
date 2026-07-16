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
      process.env.AZURE_CLIENT_SECRET
    );
  }
  return credential;
}

function otpEmail(otp, purpose) {
  const labels = {
    email_verification: 'verify your email address',
    login: 'sign in to your account',
    password_reset: 'reset your password'
  };
  const action = labels[purpose] || 'complete your request';
  return {
    subject: `Lexodd verification code: ${otp}`,
    html: `<div style="font-family:Arial,sans-serif;color:#1f2937;max-width:560px;margin:auto"><h2>Lexodd HRMS</h2><p>Use the code below to ${action}.</p><p style="font-size:28px;font-weight:700;letter-spacing:6px">${otp}</p><p>This code expires in 10 minutes. If you did not request it, you can safely ignore this email.</p></div>`
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

module.exports = { sendEmail, sendOTP };
