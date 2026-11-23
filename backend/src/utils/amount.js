// "5 boxes" / "1 box": quantities written the way people say them.
// Shared by every controller that writes a message or a notification.
const SINGULAR = { boxes: 'box', plates: 'plate', packets: 'packet', kg: 'kg' };

function amount(n, unit) {
  return n === 1 ? `1 ${SINGULAR[unit] || unit}` : `${n} ${unit}`;
}

module.exports = { amount };
