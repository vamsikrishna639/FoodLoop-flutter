// Runs after express-validator rules and stops the request if any failed.
const { validationResult } = require('express-validator');
const { ApiError } = require('../utils/apiResponse');

function validate(req, res, next) {
  const result = validationResult(req);
  if (result.isEmpty()) return next();

  // Keep the first message per field so the app can show it under the input.
  const errors = {};
  for (const e of result.array()) {
    if (!errors[e.path]) errors[e.path] = e.msg;
  }
  const first = Object.values(errors)[0];
  next(new ApiError(400, first, { errors }));
}

module.exports = validate;
