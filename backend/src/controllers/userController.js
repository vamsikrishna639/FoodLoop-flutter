// Account approval for the admin, and the volunteer list for assigning runs.
const User = require('../models/User');
const Pickup = require('../models/Pickup');
const { ok, ApiError, asyncHandler } = require('../utils/apiResponse');
const { notify } = require('../utils/notify');

// GET /api/users?status=pending&role=volunteer (admin)
// Both filters are optional and accept a comma list ("approved,rejected").
// Volunteers also get "activeRuns": how many pickups they have on the go,
// so the admin can spread the work when assigning.
exports.list = asyncHandler(async (req, res) => {
  const filter = { role: { $ne: 'admin' } };
  if (req.query.status) filter.verificationStatus = { $in: String(req.query.status).split(',') };
  if (req.query.role) filter.role = { $in: String(req.query.role).split(',').filter((r) => r !== 'admin') };

  // Waiting accounts oldest first (first come, first served); others newest first.
  const pendingOnly = req.query.status === 'pending';
  const users = await User.find(filter).sort({ createdAt: pendingOnly ? 1 : -1 });

  const volunteerIds = users.filter((u) => u.role === 'volunteer').map((u) => u._id);
  const loads = await Pickup.aggregate([
    { $match: { volunteerId: { $in: volunteerIds }, pickupStatus: { $in: ['assigned', 'picked_up'] } } },
    { $group: { _id: '$volunteerId', runs: { $sum: 1 } } },
  ]);
  const runsBy = new Map(loads.map((l) => [String(l._id), l.runs]));

  ok(res, {
    users: users.map((u) => ({
      ...u.toPublic(),
      ...(u.role === 'volunteer' ? { activeRuns: runsBy.get(String(u._id)) || 0 } : {}),
    })),
  });
});

// PATCH /api/users/:id/verify (admin)  body: { status: 'approved' | 'rejected' }
exports.verify = asyncHandler(async (req, res) => {
  const { status } = req.body;
  const user = await User.findById(req.params.id);
  if (!user) throw new ApiError(404, 'Account not found');
  if (user.role === 'admin') throw new ApiError(400, 'Admin accounts cannot be changed here');
  if (user.verificationStatus === status) {
    throw new ApiError(400, `This account is already ${status}`);
  }

  user.verificationStatus = status;
  await user.save();

  // Rule 8: tell the person their account is ready. (A rejected account
  // sees the result on its waiting screen the next time it checks.)
  if (status === 'approved') {
    await notify(user._id, 'account_approved', 'Your FoodLoop account was approved. Welcome in.');
  }

  ok(res, { user: user.toPublic() }, status === 'approved' ? `${user.name} can now sign in` : `${user.name} was not approved`);
});
