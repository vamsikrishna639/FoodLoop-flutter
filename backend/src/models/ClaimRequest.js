const mongoose = require('mongoose');

const claimRequestSchema = new mongoose.Schema(
  {
    listingId: { type: mongoose.Schema.Types.ObjectId, ref: 'FoodListing', required: true, index: true },
    recipientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    requestedQuantity: { type: Number, required: true, min: 1 },
    note: { type: String, trim: true, default: '' },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected', 'cancelled'],
      default: 'pending',
    },
    // When the donor approved or rejected (shown on the receipt timeline).
    decidedAt: { type: Date, default: null },
    // When the recipient cancelled (also shown on the receipt).
    cancelledAt: { type: Date, default: null },
  },
  {
    timestamps: true,
    // Send "id" as well as "_id", like FoodListing does.
    toJSON: { virtuals: true, versionKey: false },
  }
);

module.exports = mongoose.model('ClaimRequest', claimRequestSchema);
