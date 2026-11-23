// Every response from the API has the same shape: { success, message, data }.

// Send a successful response.
function ok(res, data = null, message = 'OK', status = 200) {
  return res.status(status).json({ success: true, message, data });
}

// An error we throw on purpose (wrong input, not allowed, not found...).
// The central error handler turns it into a JSON response.
class ApiError extends Error {
  constructor(status, message, data = null) {
    super(message);
    this.status = status;
    this.data = data;
  }
}

// Wraps an async route so rejected promises reach the error handler
// instead of crashing the request.
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

module.exports = { ok, ApiError, asyncHandler };
