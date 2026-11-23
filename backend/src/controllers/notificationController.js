// In-app notifications (rule 8). Each user only ever sees their own.
const Notification = require('../models/Notification');
const { ok, ApiError, asyncHandler } = require('../utils/apiResponse');

// How many are sent back. Older ones stay in the database.
const LIMIT = 50;

async function unreadCount(userId) {
  return Notification.countDocuments({ userId, isRead: false });
}

// GET /api/notifications - newest first, with the unread count for the badge
exports.list = asyncHandler(async (req, res) => {
  const notifications = await Notification.find({ userId: req.user._id })
    .sort({ createdAt: -1 })
    .limit(LIMIT);
  ok(res, { notifications, unreadCount: await unreadCount(req.user._id) });
});

// PATCH /api/notifications/:id/read
exports.markRead = asyncHandler(async (req, res) => {
  // userId is in the filter, so nobody can mark someone else's as read.
  const n = await Notification.findOneAndUpdate(
    { _id: req.params.id, userId: req.user._id },
    { $set: { isRead: true } },
    { new: true }
  );
  if (!n) throw new ApiError(404, 'Notification not found');
  ok(res, { notification: n, unreadCount: await unreadCount(req.user._id) }, 'Marked as read');
});

// PATCH /api/notifications/read-all
exports.markAllRead = asyncHandler(async (req, res) => {
  const result = await Notification.updateMany({ userId: req.user._id, isRead: false }, { $set: { isRead: true } });
  const n = result.modifiedCount;
  ok(res, { updated: n, unreadCount: 0 }, n === 0 ? 'Nothing new to mark' : `Marked ${n} as read`);
});
