// Claim requests: a recipient asks for part of a listing, the donor approves
// or turns it down, and the recipient may cancel.
//
// The rules from PROMPT.md Part F that live here:
//   1. No over-allocation. Approval reserves portions with ONE conditional
//      findOneAndUpdate ($expr + $inc), so two approvals at the same moment
//      can never reserve more than the listing has.
//   2. Reserved = quantity -> fully_reserved. Cancelling an approved claim
//      gives its portions back and the listing becomes available again.
//   3. Expired listings accept no new requests and no approvals.
//   5. Only valid status changes (see utils/transitions.js).
//   6. Recipients cancel only their own requests; donors decide only on
//      requests for their own listings.
//   7. One open (pending or approved) request per recipient per listing.
//   8. Notifications for "request submitted" and "approved / turned down".
const ClaimRequest = require('../models/ClaimRequest');
const FoodListing = require('../models/FoodListing');
const Pickup = require('../models/Pickup');
const { ok, ApiError, asyncHandler } = require('../utils/apiResponse');
const { expireOverdueListings } = require('../utils/listingStatus');
const { assertClaimTransition } = require('../utils/transitions');
const { notify } = require('../utils/notify');
const { amount } = require('../utils/amount');

// What is joined into every claim we send back: the listing (with its
// canteen's name, so the app can build a token from it) and the recipient.
const POPULATE = [
  { path: 'listingId', populate: { path: 'donorId', select: 'name organization' } },
  { path: 'recipientId', select: 'name organization' },
];


function personName(user) {
  return user.name || 'A recipient';
}

// Adds the pickup (if any) to each claim, so the receipt can print
// "Volunteer", "Picked up" and "Delivered". A cancelled pickup is ignored:
// the request is then waiting for a new volunteer.
async function withPickups(claims) {
  const ids = claims.map((c) => c._id);
  const pickups = await Pickup.find({ claimRequestId: { $in: ids }, pickupStatus: { $ne: 'cancelled' } })
    .populate('volunteerId', 'name');
  const byClaim = new Map(pickups.map((p) => [String(p.claimRequestId), p]));

  return claims.map((c) => {
    const p = byClaim.get(String(c._id));
    return {
      ...c.toJSON(),
      pickup: p
        ? {
            id: p._id,
            pickupStatus: p.pickupStatus,
            volunteerName: p.volunteerId ? p.volunteerId.name : '',
            assignedAt: p.assignedAt,
            pickedUpAt: p.pickedUpAt,
            deliveredAt: p.deliveredAt,
          }
        : null,
    };
  });
}

// Loads one claim with its listing and recipient, and the pickup info.
async function sendOne(res, claimId, message, status = 200) {
  const claim = await ClaimRequest.findById(claimId).populate(POPULATE);
  const [shaped] = await withPickups([claim]);
  ok(res, { claim: shaped }, message, status);
}

// Loads a claim for the donor who owns its listing (rule 6).
async function findForDonor(req) {
  const claim = await ClaimRequest.findById(req.params.id);
  if (!claim) throw new ApiError(404, 'Request not found');
  const listing = await FoodListing.findById(claim.listingId);
  if (!listing) throw new ApiError(404, 'The listing for this request no longer exists');
  if (!listing.donorId.equals(req.user._id)) {
    throw new ApiError(403, 'You can only decide on requests for your own listings');
  }
  return { claim, listing };
}

// POST /api/claims (recipient)  body: { listingId, requestedQuantity, note }
exports.create = asyncHandler(async (req, res) => {
  await expireOverdueListings();
  const { listingId, requestedQuantity, note } = req.body;

  const listing = await FoodListing.findById(listingId);
  if (!listing) throw new ApiError(404, 'Listing not found');

  // Rule 3: closed listings cannot be requested.
  if (listing.status === 'expired' || listing.pickupDeadline <= new Date()) {
    throw new ApiError(400, 'Pickup for this token has closed');
  }
  if (listing.status === 'completed') {
    throw new ApiError(400, 'This token has already been handed out');
  }

  // Rule 7: no second open request for the same listing.
  const open = await ClaimRequest.exists({
    listingId: listing._id,
    recipientId: req.user._id,
    status: { $in: ['pending', 'approved'] },
  });
  if (open) {
    throw new ApiError(409, 'You already have a request for this token. Cancel it first to ask again');
  }

  // Asking for more than is left would only be refused at approval, so
  // say so now. (Approval checks again, atomically - this is just early help.)
  const left = listing.availableQuantity;
  if (requestedQuantity > left) {
    const message = left === 0
      ? 'Every portion is already reserved'
      : `Only ${amount(left, listing.unit)} left`;
    throw new ApiError(400, message, { errors: { requestedQuantity: message } });
  }

  const claim = await ClaimRequest.create({
    listingId: listing._id,
    recipientId: req.user._id,
    requestedQuantity,
    note: note || '',
    status: 'pending',
  });

  // Rule 8: tell the canteen.
  await notify(
    listing.donorId,
    'claim_submitted',
    `${personName(req.user)} requested ${amount(requestedQuantity, listing.unit)} of ${listing.title}.`
  );

  await sendOne(res, claim._id, `Request sent for ${amount(requestedQuantity, listing.unit)} of ${listing.title}`, 201);
});

// GET /api/claims/mine (recipient) - newest first
exports.mine = asyncHandler(async (req, res) => {
  await expireOverdueListings();
  const claims = await ClaimRequest.find({ recipientId: req.user._id })
    .sort({ createdAt: -1 })
    .populate(POPULATE);
  ok(res, { claims: await withPickups(claims) });
});

// GET /api/claims/incoming (donor) - requests for the donor's own listings.
// Pending ones come first (oldest first, so nobody waits longest), then the
// decided ones, most recent first.
exports.incoming = asyncHandler(async (req, res) => {
  await expireOverdueListings();
  const listingIds = await FoodListing.find({ donorId: req.user._id }).distinct('_id');
  const claims = await ClaimRequest.find({ listingId: { $in: listingIds } })
    .sort({ updatedAt: -1 })
    .populate(POPULATE);

  const pending = claims
    .filter((c) => c.status === 'pending')
    .sort((a, b) => a.createdAt - b.createdAt);
  const decided = claims.filter((c) => c.status !== 'pending');
  ok(res, { claims: await withPickups([...pending, ...decided]) });
});

// PATCH /api/claims/:id/approve (donor who owns the listing)
exports.approve = asyncHandler(async (req, res) => {
  await expireOverdueListings();
  const { claim, listing } = await findForDonor(req);
  assertClaimTransition(claim.status, 'approved');

  if (listing.status === 'expired' || listing.pickupDeadline <= new Date()) {
    throw new ApiError(400, 'Pickup for this token has closed, so the request cannot be approved');
  }

  // Step 1: flip the claim from pending to approved. The status is part of
  // the filter, so if two clicks arrive together only one of them matches;
  // the other finds nothing and is told the request was already decided.
  const decided = await ClaimRequest.findOneAndUpdate(
    { _id: claim._id, status: 'pending' },
    { $set: { status: 'approved', decidedAt: new Date() } },
    { new: true }
  );
  if (!decided) throw new ApiError(400, 'This request has already been decided');

  // Step 2 (rule 1): reserve the portions in ONE atomic operation.
  // The filter only matches while reserved + requested <= quantity, and
  // $inc adds to the stored value inside the database. MongoDB runs the
  // filter and the update together on one document, so two approvals can
  // never both pass the check and over-reserve.
  const qty = claim.requestedQuantity;
  const reserved = await FoodListing.findOneAndUpdate(
    {
      _id: listing._id,
      status: 'available',
      pickupDeadline: { $gt: new Date() },
      $expr: { $lte: [{ $add: ['$reservedQuantity', qty] }, '$quantity'] },
    },
    { $inc: { reservedQuantity: qty } },
    { new: true }
  );

  if (!reserved) {
    // Not enough left (or the listing closed a moment ago). There is no
    // multi-document transaction on a single local MongoDB, so we undo
    // step 1 by hand: the request goes back to pending.
    await ClaimRequest.updateOne({ _id: claim._id }, { $set: { status: 'pending', decidedAt: null } });
    const fresh = await FoodListing.findById(listing._id);
    const left = fresh ? fresh.availableQuantity : 0;
    throw new ApiError(
      400,
      left === 0
        ? 'Every portion is already reserved, so this request cannot be approved'
        : `Only ${amount(left, listing.unit)} left, but this request asks for ${amount(qty, listing.unit)}`
    );
  }

  // Rule 2: everything reserved -> fully_reserved.
  if (reserved.reservedQuantity >= reserved.quantity) {
    await FoodListing.updateOne({ _id: listing._id, status: 'available' }, { $set: { status: 'fully_reserved' } });
  }

  await notify(
    claim.recipientId,
    'claim_approved',
    `Your request for ${amount(qty, listing.unit)} of ${listing.title} was approved.`
  );

  await sendOne(res, claim._id, `Approved ${amount(qty, listing.unit)} of ${listing.title}`);
});

// PATCH /api/claims/:id/reject (donor who owns the listing)
exports.reject = asyncHandler(async (req, res) => {
  const { claim, listing } = await findForDonor(req);
  assertClaimTransition(claim.status, 'rejected');

  // Same guard as approval: only a request that is still pending changes.
  const decided = await ClaimRequest.findOneAndUpdate(
    { _id: claim._id, status: 'pending' },
    { $set: { status: 'rejected', decidedAt: new Date() } },
    { new: true }
  );
  if (!decided) throw new ApiError(400, 'This request has already been decided');

  await notify(
    claim.recipientId,
    'claim_rejected',
    `Your request for ${listing.title} was not approved.`
  );

  await sendOne(res, claim._id, 'Request turned down');
});

// PATCH /api/claims/:id/cancel (the recipient who made it)
exports.cancel = asyncHandler(async (req, res) => {
  const claim = await ClaimRequest.findById(req.params.id);
  if (!claim) throw new ApiError(404, 'Request not found');
  if (!claim.recipientId.equals(req.user._id)) {
    throw new ApiError(403, 'You can only cancel your own requests');
  }
  assertClaimTransition(claim.status, 'cancelled');

  // Once a volunteer has the food, the request can no longer be taken back.
  // A pickup that is only "assigned" is cancelled along with the request.
  const pickup = await Pickup.findOne({ claimRequestId: claim._id, pickupStatus: { $ne: 'cancelled' } });
  if (pickup && pickup.pickupStatus !== 'assigned') {
    throw new ApiError(400, 'The food has already been collected, so this request cannot be cancelled');
  }

  const wasApproved = claim.status === 'approved';
  const cancelled = await ClaimRequest.findOneAndUpdate(
    { _id: claim._id, status: claim.status },
    { $set: { status: 'cancelled', cancelledAt: new Date() } },
    { new: true }
  );
  if (!cancelled) throw new ApiError(400, 'This request changed a moment ago. Refresh and try again');

  if (pickup) {
    await Pickup.updateOne({ _id: pickup._id, pickupStatus: 'assigned' }, { $set: { pickupStatus: 'cancelled', cancelledAt: new Date() } });
  }

  // Rule 2: give the portions back. $inc again, so it is atomic too.
  if (wasApproved) {
    await FoodListing.updateOne({ _id: claim.listingId }, { $inc: { reservedQuantity: -claim.requestedQuantity } });
    // A fully reserved listing has room again. (If its deadline has passed,
    // the next expiry sweep marks it expired.)
    await FoodListing.updateOne({ _id: claim.listingId, status: 'fully_reserved' }, { $set: { status: 'available' } });
  }

  await sendOne(res, claim._id, wasApproved ? 'Request cancelled. The portions are back on the counter' : 'Request cancelled');
});

// Shared with the pickup controller (the admin's "needs a volunteer" list).
exports.POPULATE = POPULATE;
exports.withPickups = withPickups;
