// Authentication and role checks used by every protected route.
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { ApiError, asyncHandler } = require('../utils/apiResponse');

// protect: requires a valid "Authorization: Bearer <token>" header and
// loads the user into req.user.
const protect = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) {
    throw new ApiError(401, 'Please log in to continue');
  }

  let payload;
  try {
    payload = jwt.verify(header.slice(7), process.env.JWT_SECRET);
  } catch (e) {
    throw new ApiError(401, 'Your session has expired. Please log in again');
  }

  const user = await User.findById(payload.id);
  if (!user) throw new ApiError(401, 'This account no longer exists');

  req.user = user;
  next();
});

// requireApproved: blocks pending or rejected accounts from using the app.
// (They can still log in and call /auth/me to see their status.)
function requireApproved(req, res, next) {
  if (req.user.verificationStatus !== 'approved') {
    return next(new ApiError(403, 'Your account is waiting for admin approval'));
  }
  next();
}

// requireRole('donor', 'admin'): only the listed roles may continue.
function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return next(
        new ApiError(403, `Only ${roles.join(' or ')} accounts can do this`)
      );
    }
    next();
  };
}

module.exports = { protect, requireApproved, requireRole };
