// Pickups: the admin assigns an approved request to a volunteer, and the
// volunteer moves the run along: assigned -> picked_up -> delivered.
//
// The rules from PROMPT.md Part F that live here:
//   4. Food counts as redistributed only when a pickup is "delivered".
//   5. Only valid status changes (see utils/transitions.js).
//   6. Volunteers update only their own pickups.
//   8. Notifications for "volunteer assigned" and "delivered".
const ClaimRequest = require('../models/ClaimRequest');
const FoodListing = require('../models/FoodListing');
const Pickup = require('../models/Pickup');
const User = require('../models/User');
const { ok, ApiError, asyncHandler } = require('../utils/apiResponse');
const { assertPickupTransition } = require('../utils/transitions');
const { completeIfDone } = require('../utils/listingStatus');
const { notify } = require('../utils/notify');
const { amount } = require('../utils/amount');
const { POPULATE, withPickups } = require('./claimController');

// A pickup that is still "live" blocks a second one for the same request.
// A cancelled pickup does not: the request can be given to someone else.
const LIVE = ['assigned', 'picked_up', 'delivered'];

// Everything the volunteer's receipt needs, in one object:
//   { id, pickupStatus, assignedAt, pickedUpAt, deliveredAt,
//     volunteerName, claim: { id, requestedQuantity, note },
//     recipient: { name, organization, phone }, listing: { ...token } }
async function shape(pickups) {
  await Pickup.populate(pickups, [
    { path: 'volunteerId', select: 'name' },
    {
      path: 'claimRequestId',
      populate: [
        { path: 'listingId', populate: { path: 'donorId', select: 'name organization' } },
        { path: 'recipientId', select: 'name organization phone' },
      ],
    },
  ]);

  return pickups
    .filter((p) => p.claimRequestId && p.claimRequestId.listingId) // skip runs whose listing was deleted
    .map((p) => {
      const claim = p.claimRequestId;
      const r = claim.recipientId || {};
      return {
        id: p._id,
        pickupStatus: p.pickupStatus,
        assignedAt: p.assignedAt,
        pickedUpAt: p.pickedUpAt,
        deliveredAt: p.deliveredAt,
        volunteerName: p.volunteerId ? p.volunteerId.name : '',
        claim: { id: claim._id, requestedQuantity: claim.requestedQuantity, note: claim.note },
        recipient: { name: r.name || 'A recipient', organization: r.organization || '', phone: r.phone || '' },
        listing: claim.listingId.toJSON(),
      };
    });
}

async function sendOne(res, pickupId, message, status = 200) {
  const pickup = await Pickup.findById(pickupId);
  const [shaped] = await shape([pickup]);
  ok(res, { pickup: shaped }, message, status);
}

// GET /api/pickups/unassigned (admin)
// Approved requests that have no live pickup yet: the admin's to-do list.
// Oldest approval first, so nothing waits longest.
exports.unassigned = asyncHandler(async (req, res) => {
  const approved = await ClaimRequest.find({ status: 'approved' }).sort({ decidedAt: 1 }).populate(POPULATE);
  const busy = await Pickup.find({
    claimRequestId: { $in: approved.map((c) => c._id) },
    pickupStatus: { $in: LIVE },
  }).distinct('claimRequestId');
  const busyIds = new Set(busy.map(String));

  const waiting = approved.filter((c) => c.listingId && !busyIds.has(String(c._id)));
  ok(res, { claims: await withPickups(waiting) });
});

// POST /api/pickups/assign (admin)  body: { claimRequestId, volunteerId }
exports.assign = asyncHandler(async (req, res) => {
  const { claimRequestId, volunteerId } = req.body;

  const claim = await ClaimRequest.findById(claimRequestId).populate('recipientId', 'name');
  if (!claim) throw new ApiError(404, 'Request not found');
  if (claim.status !== 'approved') {
    throw new ApiError(400, 'Only approved requests can be given to a volunteer');
  }

  const listing = await FoodListing.findById(claim.listingId);
  if (!listing) throw new ApiError(404, 'The listing for this request no longer exists');
  if (listing.pickupDeadline <= new Date()) {
    throw new ApiError(400, 'Pickup time for this token has passed, so no run can be assigned');
  }

  const volunteer = await User.findById(volunteerId);
  if (!volunteer || volunteer.role !== 'volunteer') throw new ApiError(400, 'Choose a volunteer');
  if (volunteer.verificationStatus !== 'approved') {
    throw new ApiError(400, `${volunteer.name}'s account is not approved yet`);
  }

  // One live run per request. (The admin is the only person who assigns,
  // so a check before creating is enough here.)
  const existing = await Pickup.exists({ claimRequestId: claim._id, pickupStatus: { $in: LIVE } });
  if (existing) throw new ApiError(409, 'This request already has a volunteer');

  const pickup = await Pickup.create({
    claimRequestId: claim._id,
    volunteerId: volunteer._id,
    pickupStatus: 'assigned',
    assignedAt: new Date(),
  });

  const what = `${amount(claim.requestedQuantity, listing.unit)} of ${listing.title}`;
  const recipientName = claim.recipientId ? claim.recipientId.name : 'a recipient';
  await notify(volunteer._id, 'volunteer_assigned', `New pickup: ${what} for ${recipientName}.`);
  await notify(claim.recipientId._id, 'volunteer_assigned', `${volunteer.name} will collect your ${listing.title}.`);

  await sendOne(res, pickup._id, `${volunteer.name} will collect ${what}`, 201);
});

// GET /api/pickups/mine (volunteer) - newest assignment first
exports.mine = asyncHandler(async (req, res) => {
  const pickups = await Pickup.find({ volunteerId: req.user._id }).sort({ assignedAt: -1 });
  ok(res, { pickups: await shape(pickups) });
});

// What each new status stamps on the pickup, and the reply's message.
const STEP = {
  picked_up: { field: 'pickedUpAt', message: 'Marked as collected. Now take it over' },
  delivered: { field: 'deliveredAt', message: 'Delivered. Thank you for the run' },
  cancelled: { field: 'cancelledAt', message: 'Run handed back. The admin will find someone else' },
};

// PATCH /api/pickups/:id/status (the volunteer it is assigned to)
// body: { status: 'picked_up' | 'delivered' | 'cancelled' }
exports.updateStatus = asyncHandler(async (req, res) => {
  const next = req.body.status;
  const pickup = await Pickup.findById(req.params.id);
  if (!pickup) throw new ApiError(404, 'Pickup not found');
  if (!pickup.volunteerId.equals(req.user._id)) {
    throw new ApiError(403, 'You can only update your own pickups');
  }
  assertPickupTransition(pickup.pickupStatus, next);

  // The current status is part of the filter, so a double tap changes the
  // pickup only once; the second tap finds nothing.
  const step = STEP[next];
  const updated = await Pickup.findOneAndUpdate(
    { _id: pickup._id, pickupStatus: pickup.pickupStatus },
    { $set: { pickupStatus: next, [step.field]: new Date() } },
    { new: true }
  );
  if (!updated) throw new ApiError(400, 'This pickup changed a moment ago. Refresh and try again');

  if (next === 'delivered') {
    // Rule 4: this is the moment the food counts as redistributed.
    const claim = await ClaimRequest.findById(pickup.claimRequestId);
    const listing = claim && (await FoodListing.findById(claim.listingId));
    if (claim && listing) {
      const what = `${listing.title} (${amount(claim.requestedQuantity, listing.unit)})`;
      await notify(claim.recipientId, 'delivered', `${what} was delivered by ${req.user.name}.`);
      await notify(listing.donorId, 'delivered', `${what} reached its recipient.`);
      await completeIfDone(listing._id);
    }
  }

  await sendOne(res, pickup._id, step.message);
});
