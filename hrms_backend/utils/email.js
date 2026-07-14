// Brevo Email Service - Ultra Simple Version
const axios = require('axios');

// Configuration from environment
const API_KEY = process.env.BREVO_API_KEY;
const SENDER_EMAIL = process.env.BREVO_SENDER_EMAIL;
const SENDER_NAME = process.env.BREVO_SENDER_NAME || 'Lexodd Hypernova';
const API_URL = 'https://api.brevo.com/v3/smtp/email';

/**
 * Send email using Brevo API
 */
async function sendEmail(to, subject, html) {
  // Check config
  if (!API_KEY || API_KEY === 'your_brevo_api_key_here') {
    console.log('WARN: BREVO_API_KEY not set');
    return { success: false, error: 'API key not set' };
  }

  if (!SENDER_EMAIL || SENDER_EMAIL.includes('example.com')) {
    console.log('WARN: BREVO_SENDER_EMAIL not set');
    return { success: false, error: 'Sender email not set' };
  }

  try {
    console.log('Calling Brevo API...');
    
    const result = await axios.post(API_URL, {
      sender: { name: SENDER_NAME, email: SENDER_EMAIL },
      to: [{ email: to, name: to }],
      subject: subject,
      htmlContent: html
    }, {
      headers: {
        'api-key': API_KEY,
        'content-type': 'application/json'
      }
    });

    console.log('Email sent! ID:', result.data.messageId);
    return { success: true, messageId: result.data.messageId };

  } catch (err) {
    if (err.response) {
      console.log('Brevo Error:', err.response.status, err.response.data);
      return { success: false, error: err.response.data.message, statusCode: err.response.status };
    }
    console.log('Error:', err.message);
    return { success: false, error: err.message };
  }
}

/**
 * Send OTP email
 */
async function sendOTP(email, otp, purpose) {
  const subjects = {
    email_verification: 'Verify Your Email - Lexodd Hypernova',
    password_reset: 'Password Reset OTP - Lexodd Hypernova',
    login: 'Login OTP - Lexodd Hypernova'
  };

  const html = `
<!DOCTYPE html>
<html>
<body style="margin:0;padding:20px;font-family:Arial;background:#f4f4f4;">
  <table width="600" style="margin:auto;background:#fff;border-radius:12px;">
    <tr>
      <td style="background:linear-gradient(135deg,#667eea,#764ba2);padding:40px;text-align:center;">
        <h1 style="color:#fff;margin:0;">EMS Portal</h1>
      </td>
    </tr>
    <tr>
      <td style="padding:40px;">
        <h2 style="color:#333;">OTP Verification</h2>
        <p style="color:#555;">Your OTP code:</p>
        <div style="background:#f8f9fa;border:3px dashed #667eea;border-radius:12px;padding:30px;text-align:center;margin:30px 0;">
          <span style="font-size:48px;font-weight:bold;color:#667eea;letter-spacing:10px;font-family:monospace;">${otp}</span>
        </div>
        <p style="color:#e74c3c;font-weight:bold;text-align:center;">Valid for 5 minutes</p>
      </td>
    </tr>
    <tr>
      <td style="background:#f8f9fa;padding:20px;text-align:center;">
        <p style="color:#999;font-size:12px;">Do not reply to this email</p>
      </td>
    </tr>
  </table>
</body>
</html>`;

  return await sendEmail(email, subjects[purpose] || 'OTP Verification', html);
}

// Export functions
module.exports = { sendEmail, sendOTP };
