// Business rule 5: only these status changes are allowed. Anything else is a
// 400 Bad Request. Keeping the rules in one table makes them easy to read
// and easy to explain: "from this status you may go to these statuses".
const { ApiError } = require('./apiResponse');

const CLAIM_TRANSITIONS = {
  pending: ['approved', 'rejected', 'cancelled'],
  approved: ['cancelled'],
  rejected: [],
  cancelled: [],
};

// Used by the pickup workflow in Stage 4.
const PICKUP_TRANSITIONS = {
  assigned: ['picked_up', 'cancelled'],
  picked_up: ['delivered', 'cancelled'],
  delivered: [],
  cancelled: [],
};

// Plain words for messages, e.g. "A rejected request cannot be approved".
const CLAIM_WORDS = {
  pending: 'pending', approved: 'approved', rejected: 'turned-down', cancelled: 'cancelled',
};
const CLAIM_VERBS = { approved: 'approved', rejected: 'turned down', cancelled: 'cancelled' };

function canMove(table, from, to) {
  return (table[from] || []).includes(to);
}

// Throws a 400 when a claim may not go from `from` to `to`.
function assertClaimTransition(from, to) {
  if (!canMove(CLAIM_TRANSITIONS, from, to)) {
    const article = from === 'approved' ? 'An' : 'A';
    throw new ApiError(400, `${article} ${CLAIM_WORDS[from] || from} request cannot be ${CLAIM_VERBS[to] || to}`);
  }
}

function assertPickupTransition(from, to) {
  if (!canMove(PICKUP_TRANSITIONS, from, to)) {
    throw new ApiError(400, `A pickup that is ${from.replace('_', ' ')} cannot become ${to.replace('_', ' ')}`);
  }
}

module.exports = {
  CLAIM_TRANSITIONS,
  PICKUP_TRANSITIONS,
  assertClaimTransition,
  assertPickupTransition,
};
