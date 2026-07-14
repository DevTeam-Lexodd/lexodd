require('dotenv').config();
const { sendOTP } = require('./utils/email');

const testEmail = process.argv[2];

if (!testEmail) {
  console.log('');
  console.log('Usage: node test-brevo.js your_email@example.com');
  console.log('');
  process.exit(0);
}

async function runTest() {
  console.log('');
  console.log('===========================================');
  console.log('  Brevo Email Test');
  console.log('===========================================');
  console.log('');
  console.log('Config:');
  console.log('  API Key:', process.env.BREVO_API_KEY ? process.env.BREVO_API_KEY.substring(0, 20) + '...' : 'NOT SET');
  console.log('  Sender:', process.env.BREVO_SENDER_EMAIL || 'NOT SET');
  console.log('  Target:', testEmail);
  console.log('');

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  
  console.log('Sending OTP email...');
  console.log('OTP Code:', otp);
  console.log('');

  const result = await sendOTP(testEmail, otp, 'email_verification');

  console.log('');
  if (result.success) {
    console.log('SUCCESS!');
    console.log('Message ID:', result.messageId);
    console.log('');
    console.log('Check your email inbox!');
    console.log('OTP Code:', otp);
  } else {
    console.log('FAILED');
    console.log('Error:', result.error);
    if (result.statusCode) console.log('Status:', result.statusCode);
  }
  console.log('');
  console.log('===========================================');
  console.log('');
}

runTest();
