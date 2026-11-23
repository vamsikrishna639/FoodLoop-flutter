// Food listings: browse, post, edit, delete.
//
// Who may do what (the routes add the role checks, this file adds ownership):
//   - every approved user can browse and open listings
//   - donors post listings and manage only their own
//   - admins can edit or delete any listing
const FoodListing = require('../models/FoodListing');
const ClaimRequest = require('../models/ClaimRequest');
const { ok, ApiError, asyncHandler } = require('../utils/apiResponse');
const { expireOverdueListings, openStatusFor } = require('../utils/listingStatus');

// Fields a donor is allowed to set. Anything else in the body (status,
// reservedQuantity, tokenNumber, donorId...) is ignored on purpose.
const EDITABLE = [
  'title', 'description', 'quantity', 'unit', 'location',
  'preparedAt', 'pickupDeadline', 'foodType', 'allergenNotes', 'imageUrl',
];

// The donor's name is shown on every token, so it is joined in.
const DONOR_FIELDS = 'name organization';

// A "closing soon" listing has less than this long left.
const CLOSING_SOON_MS = 60 * 60 * 1000;

// Copies only the editable fields that were actually sent.
function pickEditable(body) {
  const out = {};
  for (const key of EDITABLE) {
    if (body[key] !== undefined) out[key] = body[key];
  }
  return out;
}

// Time rules for a listing. They are checked here, not in the validator,
// because an edit may change only one of the two dates and the rule needs
// both. Errors are sent per field so the form shows them under the input.
function checkTimes(preparedAt, pickupDeadline) {
  const now = Date.now();
  const leeway = 5 * 60 * 1000; // allow for a phone clock a few minutes fast

  if (new Date(preparedAt).getTime() > now + leeway) {
    const message = 'Prepared time cannot be in the future';
    throw new ApiError(400, message, { errors: { preparedAt: message } });
  }
  if (new Date(pickupDeadline).getTime() <= now) {
    const message = 'Pickup deadline must be in the future';
    throw new ApiError(400, message, { errors: { pickupDeadline: message } });
  }
  if (new Date(pickupDeadline) <= new Date(preparedAt)) {
    const message = 'Pickup deadline must be after the prepared time';
    throw new ApiError(400, message, { errors: { pickupDeadline: message } });
  }
}

// Turns user text into a safe regular expression (so "a+b" is not a pattern).
function escapeRegex(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Loads a listing and checks that the current user may change it.
async function findEditable(req) {
  const listing = await FoodListing.findById(req.params.id);
  if (!listing) throw new ApiError(404, 'Listing not found');

  const isOwner = listing.donorId.equals(req.user._id);
  if (req.user.role !== 'admin' && !isOwner) {
    throw new ApiError(403, 'You can only manage your own listings');
  }
  return listing;
}

// GET /api/foods?status=available,fully_reserved&foodType=veg&search=rice&closingSoon=true
exports.list = asyncHandler(async (req, res) => {
  await expireOverdueListings();

  const { status, foodType, search, closingSoon } = req.query;
  const filter = {};

  // status may be one value or a comma-separated list.
  if (status) filter.status = { $in: String(status).split(',').map((s) => s.trim()) };
  if (foodType) filter.foodType = foodType;
  if (search && String(search).trim()) {
    const pattern = new RegExp(escapeRegex(String(search).trim()), 'i');
    filter.$or = [{ title: pattern }, { description: pattern }, { location: pattern }];
  }
  if (closingSoon === 'true') {
    const now = new Date();
    filter.pickupDeadline = { $gt: now, $lte: new Date(now.getTime() + CLOSING_SOON_MS) };
  }

  // Soonest deadline first: the deadline is the most important fact.
  const listings = await FoodListing.find(filter)
    .sort({ pickupDeadline: 1 })
    .populate('donorId', DONOR_FIELDS);

  ok(res, { listings });
});

// GET /api/foods/mine (donor) - newest first
exports.mine = asyncHandler(async (req, res) => {
  await expireOverdueListings();
  const listings = await FoodListing.find({ donorId: req.user._id })
    .sort({ createdAt: -1 })
    .populate('donorId', DONOR_FIELDS);
  ok(res, { listings });
});

// GET /api/foods/:id
exports.getOne = asyncHandler(async (req, res) => {
  await expireOverdueListings();
  const listing = await FoodListing.findById(req.params.id).populate('donorId', DONOR_FIELDS);
  if (!listing) throw new ApiError(404, 'Listing not found');
  ok(res, { listing });
});

// POST /api/foods (donor)
exports.create = asyncHandler(async (req, res) => {
  const data = pickEditable(req.body);
  checkTimes(data.preparedAt, data.pickupDeadline);

  // create() (not insertMany) so the pre-save hook assigns the token number.
  const listing = await FoodListing.create({
    ...data,
    donorId: req.user._id,
    reservedQuantity: 0,
    status: 'available',
  });
  await listing.populate('donorId', DONOR_FIELDS);

  ok(res, { listing }, `Token #${listing.tokenNumber} is on the counter`, 201);
});

// PATCH /api/foods/:id (donor who owns it, or admin)
exports.update = asyncHandler(async (req, res) => {
  await expireOverdueListings();
  const listing = await findEditable(req);

  if (listing.status === 'expired' || listing.status === 'completed') {
    throw new ApiError(400, 'This listing has closed and can no longer be edited');
  }

  const changes = pickEditable(req.body);

  // Portions already promised to approved requests cannot be taken back.
  if (changes.quantity !== undefined && changes.quantity < listing.reservedQuantity) {
    const message = `${listing.reservedQuantity} ${listing.unit} are already reserved, so the quantity cannot go below that`;
    throw new ApiError(400, message, { errors: { quantity: message } });
  }

  // Check the dates as they will be after the edit.
  checkTimes(changes.preparedAt ?? listing.preparedAt, changes.pickupDeadline ?? listing.pickupDeadline);

  listing.set(changes);
  listing.status = openStatusFor(listing); // e.g. more quantity -> available again
  await listing.save();
  await listing.populate('donorId', DONOR_FIELDS);

  ok(res, { listing }, `Token #${listing.tokenNumber} updated`);
});

// DELETE /api/foods/:id (donor who owns it with no approved claims, or admin)
exports.remove = asyncHandler(async (req, res) => {
  const listing = await findEditable(req);

  // Food promised to someone cannot disappear from under them.
  const hasApproved = await ClaimRequest.exists({ listingId: listing._id, status: 'approved' });
  if (hasApproved) {
    throw new ApiError(409, 'This listing has approved requests, so it cannot be deleted');
  }

  // Pending, rejected and cancelled requests go with the listing.
  await ClaimRequest.deleteMany({ listingId: listing._id });
  await listing.deleteOne();

  ok(res, { id: listing._id }, `Token #${listing.tokenNumber} deleted`);
});
