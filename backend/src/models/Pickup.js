const mongoose = require('mongoose');

// A volunteer's run: collect an approved request from the canteen and
// deliver it to the recipient. Status changes are limited to the table in
// utils/transitions.js: assigned -> picked_up -> delivered, and assigned /
// picked_up -> cancelled.
const pickupSchema = new mongoose.Schema(
  {
    claimRequestId: { type: mongoose.Schema.Types.ObjectId, ref: 'ClaimRequest', required: true, index: true },
    volunteerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    pickupStatus: {
      type: String,
      enum: ['assigned', 'picked_up', 'delivered', 'cancelled'],
      default: 'assigned',
    },
    assignedAt: { type: Date, default: Date.now },
    pickedUpAt: { type: Date, default: null },
    deliveredAt: { type: Date, default: null },
    // When the run was called off (by the volunteer, or because the
    // recipient cancelled the request). Shown in the activity feed.
    cancelledAt: { type: Date, default: null },
  },
  { timestamps: true, toJSON: { virtuals: true, versionKey: false } }
);

module.exports = mongoose.model('Pickup', pickupSchema);
