// A single public figure for the welcome screen: how much food has really
// reached people. Business rule 4: food counts only once a pickup is
// "delivered", so we add up the quantities of delivered claims.
const Pickup = require('../models/Pickup');
const { ok, asyncHandler } = require('../utils/apiResponse');

// GET /api/impact (public, no login)
exports.summary = asyncHandler(async (req, res) => {
  const delivered = await Pickup.find({ pickupStatus: 'delivered' })
    .populate('claimRequestId', 'requestedQuantity');

  const portionsDelivered = delivered.reduce(
    (sum, p) => sum + (p.claimRequestId ? p.claimRequestId.requestedQuantity : 0),
    0
  );

  ok(res, { portionsDelivered, deliveries: delivered.length });
});
