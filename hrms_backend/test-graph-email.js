require('dotenv').config();
const { sendOTP } = require('./utils/email');

const recipient = process.argv[2];
if (!recipient) {
  console.error('Usage: npm run test-email -- recipient@example.com');
  process.exit(1);
}

sendOTP(recipient, '123456', 'email_verification')
  .then((result) => {
    if (!result.success) {
      console.error('Email was not sent:', result);
      process.exitCode = 1;
      return;
    }
    console.log(`Microsoft Graph email sent to ${recipient}`);
  })
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
