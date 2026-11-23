// Business rule 8: in-app notifications. One small helper so every
// controller creates them the same way. The Alerts screen arrives in Stage 4;
// the notifications are already stored from Stage 3 on.
const Notification = require('../models/Notification');

// type: claim_submitted | claim_approved | claim_rejected | volunteer_assigned
//       | delivered | account_approved
async function notify(userId, type, message) {
  await Notification.create({ userId, type, message });
}

module.exports = { notify };
