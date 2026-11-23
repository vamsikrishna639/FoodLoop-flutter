// Creates one approved admin account. Admins cannot register through the
// app (the register route refuses the role), so this script and the seed are
// the only ways to make one.
//
// Usage (from backend/):
//   npm run create-admin -- "Full Name" admin@example.com "a-strong-password"
//   npm run create-admin -- "Full Name" admin@example.com "a-strong-password" 9876543210
//
// The fourth argument (phone) is optional. The "--" tells npm that what
// follows belongs to the script, not to npm itself.
//
// Nothing is printed or saved except the account itself: the password is
// hashed with bcrypt before it reaches the database, and it is never logged.
require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const connectDB = require('../src/config/db');
const User = require('../src/models/User');

// The same rules the register form uses, so an admin account is never weaker
// than a normal one.
function check(name, email, password, phone) {
  const problems = [];
  if (!name || name.trim().length < 2) problems.push('Name must be at least 2 characters.');
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) problems.push('Email is not valid.');
  if (!password || password.length < 6) problems.push('Password must be at least 6 characters.');
  if (phone && !/^[0-9+\- ]{7,15}$/.test(phone.trim())) problems.push('Phone must be 7 to 15 digits.');
  return problems;
}

function usage(problems) {
  if (problems.length) console.error(problems.map((p) => `  - ${p}`).join('\n'));
  console.error('\nUsage: npm run create-admin -- "Full Name" email password [phone]');
  process.exit(1);
}

async function main() {
  const [name, email, password, phone] = process.argv.slice(2);
  if (!name || !email || !password) usage(['Name, email and password are all required.']);
  const problems = check(name, email, password, phone);
  if (problems.length) usage(problems);

  await connectDB();

  // Never overwrite an existing account (it could be someone else's).
  const cleanEmail = email.trim().toLowerCase();
  if (await User.exists({ email: cleanEmail })) {
    console.error(`An account with the email ${cleanEmail} already exists. Nothing was changed.`);
    process.exitCode = 1;
    return;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  await User.create({
    name: name.trim(),
    email: cleanEmail,
    passwordHash,
    role: 'admin',
    phone: phone ? phone.trim() : 'Not given', // the model needs a phone
    organization: 'Campus Admin',
    verificationStatus: 'approved', // an admin is approved from the start
  });

  console.log(`Admin account created for ${cleanEmail}. Sign in with the password you chose.`);
}

main()
  .catch((err) => {
    console.error('Could not create the admin:', err.message);
    process.exitCode = 1;
  })
  .finally(() => mongoose.disconnect());
