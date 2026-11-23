// Two read-only endpoints built from the data that already exists:
//
//   GET /api/dashboard  the signed-in role's figures and a 7-day series
//   GET /api/activity   recent events for the activity feed
//
// Neither has its own collection. Events are worked out from the dates
// already stored on listings, claims and pickups (createdAt, decidedAt,
// cancelledAt, assignedAt, pickedUpAt, deliveredAt), so nothing can get out
// of step and there is nothing extra to explain.
//
// Both are scoped by role (the user's choice in Stage 4):
//   admin      everything
//   donor      their own listings, the requests on them and those pickups
//   recipient  their own requests and pickups, plus new food on the counter
//   volunteer  their own runs
const User = require('../models/User');
const FoodListing = require('../models/FoodListing');
const ClaimRequest = require('../models/ClaimRequest');
const Pickup = require('../models/Pickup');
const { ok, asyncHandler } = require('../utils/apiResponse');
const { expireOverdueListings } = require('../utils/listingStatus');
const { amount } = require('../utils/amount');

const DAY_MS = 24 * 60 * 60 * 1000;

// Which listings, claims and pickups belong to this user's view.
// Returns MongoDB filters; null means "none at all".
async function scopeFor(user) {
  switch (user.role) {
    case 'admin':
      return { listings: {}, claims: {}, pickups: {} };
    case 'donor': {
      const listingIds = await FoodListing.find({ donorId: user._id }).distinct('_id');
      const claimIds = await ClaimRequest.find({ listingId: { $in: listingIds } }).distinct('_id');
      return {
        listings: { donorId: user._id },
        claims: { listingId: { $in: listingIds } },
        pickups: { claimRequestId: { $in: claimIds } },
      };
    }
    case 'recipient': {
      const claimIds = await ClaimRequest.find({ recipientId: user._id }).distinct('_id');
      return {
        listings: {}, // new food on the counter is public anyway
        claims: { recipientId: user._id },
        pickups: { claimRequestId: { $in: claimIds } },
      };
    }
    default: // volunteer
      return { listings: null, claims: null, pickups: { volunteerId: user._id } };
  }
}

// Delivered pickups in this view, with the quantity of each.
// Rule 4: only "delivered" counts as food redistributed.
async function deliveredIn(pickupFilter) {
  const pickups = await Pickup.find({ ...pickupFilter, pickupStatus: 'delivered' })
    .populate('claimRequestId', 'requestedQuantity');
  return pickups.map((p) => ({
    at: p.deliveredAt || p.updatedAt,
    portions: p.claimRequestId ? p.claimRequestId.requestedQuantity : 0,
  }));
}

// The last seven days, oldest first, today last. Days use the server's
// local time, which is the same machine as the demo.
function lastSevenDays(delivered) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const days = [];
  for (let i = 6; i >= 0; i--) {
    const start = new Date(today.getTime() - i * DAY_MS);
    const end = new Date(start.getTime() + DAY_MS);
    const inDay = delivered.filter((d) => d.at >= start && d.at < end);
    days.push({
      // "2026-11-14" without a time, so the app reads it as a local date.
      date: `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, '0')}-${String(start.getDate()).padStart(2, '0')}`,
      deliveries: inDay.length,
      portions: inDay.reduce((sum, d) => sum + d.portions, 0),
    });
  }
  return days;
}

const sum = (list) => list.reduce((s, d) => s + d.portions, 0);
const openListing = () => ({ status: { $in: ['available', 'fully_reserved'] }, pickupDeadline: { $gt: new Date() } });

// GET /api/dashboard
exports.dashboard = asyncHandler(async (req, res) => {
  await expireOverdueListings();
  const user = req.user;
  const scope = await scopeFor(user);
  const delivered = await deliveredIn(scope.pickups);
  const figures = {};

  if (user.role === 'admin') {
    const approved = await ClaimRequest.find({ status: 'approved' }).distinct('_id');
    const covered = await Pickup.find({
      claimRequestId: { $in: approved },
      pickupStatus: { $in: ['assigned', 'picked_up', 'delivered'] },
    }).distinct('claimRequestId');
    Object.assign(figures, {
      portionsDelivered: sum(delivered),
      deliveries: delivered.length,
      awaitingVolunteer: approved.length - covered.length,
      runsOnTheWay: await Pickup.countDocuments({ pickupStatus: { $in: ['assigned', 'picked_up'] } }),
      pendingAccounts: await User.countDocuments({ verificationStatus: 'pending' }),
      openListings: await FoodListing.countDocuments(openListing()),
    });
  } else if (user.role === 'donor') {
    Object.assign(figures, {
      portionsDelivered: sum(delivered),
      deliveries: delivered.length,
      openListings: await FoodListing.countDocuments({ ...scope.listings, ...openListing() }),
      waitingRequests: await ClaimRequest.countDocuments({ ...scope.claims, status: 'pending' }),
    });
  } else if (user.role === 'recipient') {
    Object.assign(figures, {
      portionsReceived: sum(delivered),
      deliveries: delivered.length,
      openRequests: await ClaimRequest.countDocuments({ recipientId: user._id, status: { $in: ['pending', 'approved'] } }),
    });
  } else {
    Object.assign(figures, {
      runsDelivered: delivered.length,
      portionsCarried: sum(delivered),
      activeRuns: await Pickup.countDocuments({ volunteerId: user._id, pickupStatus: { $in: ['assigned', 'picked_up'] } }),
    });
  }

  ok(res, { role: user.role, figures, last7Days: lastSevenDays(delivered) });
});

// ---------------------------------------------------------------------------
// Activity feed
// ---------------------------------------------------------------------------

// How many events are sent, and how many recent documents of each kind are
// read to find them. The feed is a glance at "what just happened", not a log.
const FEED_SIZE = 25;
const READ_EACH = 30;

// GET /api/activity
exports.activity = asyncHandler(async (req, res) => {
  const me = req.user;
  const scope = await scopeFor(me);
  const isMe = (u) => u && u._id && u._id.equals(me._id);
  // "You requested ..." for the viewer's own actions, a name for everyone else.
  const who = (u, fallback) => (isMe(u) ? 'You' : (u && u.name) || fallback);
  const whose = (u, fallback) => (isMe(u) ? 'your' : `${(u && u.name) || fallback}'s`);

  const events = [];
  const add = (kind, at, id, text) => {
    if (at) events.push({ id: `${kind}-${id}`, kind, at, text });
  };

  if (scope.listings) {
    const listings = await FoodListing.find(scope.listings)
      .sort({ createdAt: -1 }).limit(READ_EACH).populate('donorId', 'name');
    for (const l of listings) {
      add('posted', l.createdAt, l._id, `${who(l.donorId, 'The canteen')} posted ${amount(l.quantity, l.unit)} of ${l.title}`);
    }
  }

  if (scope.claims) {
    const claims = await ClaimRequest.find(scope.claims)
      .sort({ updatedAt: -1 }).limit(READ_EACH)
      .populate('recipientId', 'name')
      .populate('listingId', 'title unit');
    for (const c of claims) {
      if (!c.listingId) continue;
      const r = c.recipientId;
      const title = c.listingId.title;
      add('requested', c.createdAt, c._id, `${who(r, 'A recipient')} requested ${amount(c.requestedQuantity, c.listingId.unit)} of ${title}`);
      if (c.decidedAt && c.status !== 'rejected') {
        add('approved', c.decidedAt, c._id, capital(`${whose(r, 'A recipient')} request for ${title} was approved`));
      }
      if (c.status === 'rejected') {
        add('rejected', c.decidedAt, c._id, capital(`${whose(r, 'A recipient')} request for ${title} was turned down`));
      }
      if (c.status === 'cancelled') {
        add('cancelled', c.cancelledAt, c._id, `${who(r, 'A recipient')} cancelled a request for ${title}`);
      }
    }
  }

  if (scope.pickups) {
    const pickups = await Pickup.find(scope.pickups)
      .sort({ updatedAt: -1 }).limit(READ_EACH)
      .populate('volunteerId', 'name')
      .populate({ path: 'claimRequestId', populate: [{ path: 'recipientId', select: 'name' }, { path: 'listingId', select: 'title unit' }] });
    for (const p of pickups) {
      const c = p.claimRequestId;
      if (!c || !c.listingId) continue;
      const v = p.volunteerId;
      const title = c.listingId.title;
      add('assigned', p.assignedAt, p._id, isMe(v)
        ? `You were given the run for ${whose(c.recipientId, 'a recipient')} ${title}`
        : `${who(v, 'A volunteer')} will collect ${whose(c.recipientId, 'a recipient')} ${title}`);
      add('picked_up', p.pickedUpAt, p._id, `${who(v, 'A volunteer')} collected ${title} from the canteen`);
      add('delivered', p.deliveredAt, p._id,
        `${who(v, 'A volunteer')} delivered ${amount(c.requestedQuantity, c.listingId.unit)} of ${title} to ${who(c.recipientId, 'a recipient').replace(/^You$/, 'you')}`);
      // A run cancelled together with its request is already covered by
      // the "cancelled a request" line.
      if (p.pickupStatus === 'cancelled' && c.status !== 'cancelled') {
        add('cancelled', p.cancelledAt, p._id, `${who(v, 'A volunteer')} handed back the run for ${title}`);
      }
    }
  }

  events.sort((a, b) => b.at - a.at);
  ok(res, { events: events.slice(0, FEED_SIZE) });
});

// "your request ..." at the start of a sentence -> "Your request ...".
function capital(text) {
  return text.charAt(0).toUpperCase() + text.slice(1);
}
