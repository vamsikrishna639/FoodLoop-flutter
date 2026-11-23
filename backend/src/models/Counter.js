// A tiny collection that hands out sequential numbers.
// Used for token numbers (FL-0001, FL-0002, ...). $inc is atomic, so two
// listings created at the same moment can never get the same number.
const mongoose = require('mongoose');

const counterSchema = new mongoose.Schema({
  _id: { type: String },
  seq: { type: Number, default: 0 },
});

counterSchema.statics.next = async function (name) {
  const doc = await this.findOneAndUpdate(
    { _id: name },
    { $inc: { seq: 1 } },
    { returnDocument: 'after', upsert: true }
  );
  return doc.seq;
};

module.exports = mongoose.model('Counter', counterSchema);
