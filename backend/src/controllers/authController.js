// Register, login and "who am I".
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { ok, ApiError, asyncHandler } = require('../utils/apiResponse');

// Create a signed JWT that carries only the user id.
function signToken(user) {
  return jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
}

// POST /api/auth/register
exports.register = asyncHandler(async (req, res) => {
  const { name, email, password, role, phone, organization } = req.body;

  const exists = await User.findOne({ email });
  if (exists) {
    // Sent as a field error (same shape as validation errors) so the app can
    // show it under the email input.
    const message = 'An account with this email already exists';
    throw new ApiError(409, message, { errors: { email: message } });
  }

  const passwordHash = await bcrypt.hash(password, 10);

  // The role comes from a validated list that does NOT include "admin",
  // and every new account starts as pending until an admin approves it.
  const user = await User.create({
    name,
    email,
    passwordHash,
    role,
    phone,
    organization: organization || '',
    verificationStatus: 'pending',
  });

  ok(
    res,
    { token: signToken(user), user: user.toPublic() },
    'Account created. An admin will approve it shortly.',
    201
  );
});

// POST /api/auth/login
exports.login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  // passwordHash is hidden by default, so ask for it explicitly.
  const user = await User.findOne({ email }).select('+passwordHash');

  // Same message for "no such email" and "wrong password" so we do not
  // reveal which emails are registered.
  const valid = user && (await bcrypt.compare(password, user.passwordHash));
  if (!valid) throw new ApiError(401, 'Incorrect email or password');

  ok(res, { token: signToken(user), user: user.toPublic() }, 'Logged in');
});

// GET /api/auth/me
exports.me = asyncHandler(async (req, res) => {
  ok(res, { user: req.user.toPublic() });
});
