// Centralized error handling: one place decides how every error looks.
const { ApiError } = require('../utils/apiResponse');

// 404 for any route that does not exist.
function notFound(req, res, next) {
  next(new ApiError(404, `Route not found: ${req.method} ${req.originalUrl}`));
}

// Express recognises an error handler by its four arguments.
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  let status = err.status || 500;
  let message = err.message || 'Something went wrong';
  const data = err.data || null;

  // Mongoose: badly formed ObjectId in the URL.
  if (err.name === 'CastError') {
    status = 400;
    message = `Invalid ${err.path === '_id' ? 'id' : err.path}`;
  }
  // Mongoose: schema validation failed.
  if (err.name === 'ValidationError') {
    status = 400;
    message = Object.values(err.errors).map((e) => e.message).join(', ');
  }
  // MongoDB: unique index violated (e.g. email already registered).
  if (err.code === 11000) {
    status = 409;
    const field = Object.keys(err.keyValue || {})[0] || 'value';
    message = `That ${field} is already in use`;
  }
  // Broken JSON in the request body.
  if (err.type === 'entity.parse.failed') {
    status = 400;
    message = 'Request body is not valid JSON';
  }

  if (status >= 500) {
    console.error(err);
    message = 'Something went wrong on the server';
  }
  res.status(status).json({ success: false, message, data });
}

module.exports = { notFound, errorHandler };
