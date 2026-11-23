const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    // Never store the plain password. select:false keeps the hash out of queries.
    passwordHash: { type: String, required: true, select: false },
    role: {
      type: String,
      enum: ['donor', 'recipient', 'volunteer', 'admin'],
      required: true,
    },
    phone: { type: String, required: true, trim: true },
    organization: { type: String, trim: true, default: '' },
    verificationStatus: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
    },
  },
  { timestamps: true }
);

// Shape sent to the client (no hash, id instead of _id).
userSchema.methods.toPublic = function () {
  return {
    id: this._id,
    name: this.name,
    email: this.email,
    role: this.role,
    phone: this.phone,
    organization: this.organization,
    verificationStatus: this.verificationStatus,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('User', userSchema);
