const express = require('express');
const { body, param } = require('express-validator');
const validate = require('../middleware/validate');
const { protect, requireApproved, requireRole } = require('../middleware/auth');
const pickups = require('../controllers/pickupController');

const router = express.Router();

// Every pickup route needs a logged-in, approved account.
router.use(protect, requireApproved);

const assignRules = [
  body('claimRequestId').isMongoId().withMessage('Choose a request to assign'),
  body('volunteerId').isMongoId().withMessage('Choose a volunteer'),
];

const statusRules = [
  param('id').isMongoId().withMessage('Invalid id'),
  // The transition table decides which of these is allowed right now.
  body('status')
    .isIn(['picked_up', 'delivered', 'cancelled'])
    .withMessage('Status must be picked_up, delivered or cancelled'),
];

router.get('/unassigned', requireRole('admin'), pickups.unassigned);
router.post('/assign', requireRole('admin'), assignRules, validate, pickups.assign);
router.get('/mine', requireRole('volunteer'), pickups.mine);
router.patch('/:id/status', requireRole('volunteer'), statusRules, validate, pickups.updateStatus);

module.exports = router;
