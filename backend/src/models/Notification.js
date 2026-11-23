const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    message: { type: String, required: true },
    // claim_submitted | claim_approved | claim_rejected | volunteer_assigned
    // | delivered | account_approved
    type: { type: String, required: true },
    isRead: { type: Boolean, default: false },
  },
  { timestamps: { createdAt: true, updatedAt: false }, toJSON: { virtuals: true, versionKey: false } }
);

module.exports = mongoose.model('Notification', notificationSchema);
