// Small helpers that keep a listing's status in line with the business rules.
const FoodListing = require('../models/FoodListing');
const ClaimRequest = require('../models/ClaimRequest');
const Pickup = require('../models/Pickup');

// Rule 3: a listing whose pickup deadline has passed is expired.
//
// Rather than running a background timer, we "sweep" just before any read:
// one updateMany marks every overdue open listing as expired. This keeps the
// logic in one place and needs no scheduler, which is easy to explain.
//
// Only "available" listings are swept. A fully reserved listing has already
// been handed out to approved requests and its pickups carry on; if one of
// those requests is cancelled the listing goes back to "available" (rule 2)
// and the next sweep expires it if the deadline has passed.
async function expireOverdueListings() {
  await FoodListing.updateMany(
    { status: 'available', pickupDeadline: { $lte: new Date() } },
    { $set: { status: 'expired' } }
  );
}

// Rule 2: reservedQuantity === quantity means "fully_reserved".
// Used after a listing's quantity is edited. Closed listings keep their status.
function openStatusFor(listing) {
  if (listing.status === 'expired' || listing.status === 'completed') return listing.status;
  if (listing.pickupDeadline <= new Date()) return 'expired';
  return listing.reservedQuantity >= listing.quantity ? 'fully_reserved' : 'available';
}

// A listing is "completed" when its food has all been handed out: nothing
// more can be given (every portion is reserved, or pickup has closed) and
// every approved request on it has been delivered. Called after each
// delivery. Returns true when the listing was just completed.
async function completeIfDone(listingId) {
  const listing = await FoodListing.findById(listingId);
  if (!listing || listing.status === 'completed') return false;

  const nothingMoreToGive = listing.reservedQuantity >= listing.quantity || listing.pickupDeadline <= new Date();
  if (!nothingMoreToGive) return false;

  const approved = await ClaimRequest.find({ listingId, status: 'approved' }).distinct('_id');
  if (approved.length === 0) return false;
  const delivered = await Pickup.countDocuments({ claimRequestId: { $in: approved }, pickupStatus: 'delivered' });
  if (delivered < approved.length) return false;

  await FoodListing.updateOne({ _id: listingId, status: { $ne: 'completed' } }, { $set: { status: 'completed' } });
  return true;
}

module.exports = { expireOverdueListings, openStatusFor, completeIfDone };
