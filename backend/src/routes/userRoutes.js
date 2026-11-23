const express = require('express');
const { body, param, query } = require('express-validator');
const validate = require('../middleware/validate');
const { protect, requireApproved, requireRole } = require('../middleware/auth');
const users = require('../controllers/userController');

const router = express.Router();

// Only an approved admin manages accounts.
router.use(protect, requireApproved, requireRole('admin'));

router.get(
  '/',
  [
    query('status').optional().matches(/^(pending|approved|rejected)(,(pending|approved|rejected))*$/)
      .withMessage('Status must be pending, approved or rejected'),
    query('role').optional().matches(/^(donor|recipient|volunteer)(,(donor|recipient|volunteer))*$/)
      .withMessage('Role must be donor, recipient or volunteer'),
  ],
  validate,
  users.list
);

router.patch(
  '/:id/verify',
  [
    param('id').isMongoId().withMessage('Invalid id'),
    body('status').isIn(['approved', 'rejected']).withMessage('Status must be approved or rejected'),
  ],
  validate,
  users.verify
);

module.exports = router;
