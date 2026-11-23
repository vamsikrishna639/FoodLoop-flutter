const mongoose = require('mongoose');
const Counter = require('./Counter');

const foodListingSchema = new mongoose.Schema(
  {
    donorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    tokenNumber: { type: String, unique: true }, // e.g. FL-0042, set automatically
    title: { type: String, required: true, trim: true },
    description: { type: String, trim: true, default: '' },
    quantity: { type: Number, required: true, min: 1 },
    unit: { type: String, enum: ['boxes', 'plates', 'kg', 'packets'], required: true },
    reservedQuantity: { type: Number, default: 0, min: 0 },
    location: { type: String, required: true, trim: true },
    preparedAt: { type: Date, required: true },
    pickupDeadline: { type: Date, required: true },
    foodType: { type: String, enum: ['veg', 'non-veg', 'mixed'], required: true },
    allergenNotes: { type: String, trim: true, default: '' },
    imageUrl: { type: String, trim: true, default: '' },
    status: {
      type: String,
      enum: ['available', 'fully_reserved', 'expired', 'completed'],
      default: 'available',
      index: true,
    },
  },
  {
    timestamps: true,
    // Include virtuals (availableQuantity) and "id" when sent as JSON.
    toJSON: { virtuals: true, versionKey: false },
  }
);

// Available = quantity - reservedQuantity (business rule 1).
// A virtual is computed on the fly, so it can never get out of sync.
foodListingSchema.virtual('availableQuantity').get(function () {
  return Math.max(0, this.quantity - this.reservedQuantity);
});

// Give every new listing the next token number.
foodListingSchema.pre('save', async function () {
  if (this.isNew && !this.tokenNumber) {
    const seq = await Counter.next('foodListing');
    this.tokenNumber = `FL-${String(seq).padStart(4, '0')}`;
  }
});

module.exports = mongoose.model('FoodListing', foodListingSchema);
