const express = require('express');
const { body, param } = require('express-validator');
const validate = require('../middleware/validate');
const { protect, requireApproved, requireRole } = require('../middleware/auth');
const claims = require('../controllers/claimController');

const router = express.Router();

// Every claim route needs a logged-in, approved account.
router.use(protect, requireApproved);

const createRules = [
  body('listingId').isMongoId().withMessage('Choose a listing to request'),
  body('requestedQuantity')
    .isInt({ min: 1, max: 1000 })
    .withMessage('Ask for at least 1 portion')
    .toInt(),
  body('note')
    .optional({ values: 'null' })
    .trim()
    .isLength({ max: 200 })
    .withMessage('Keep the note under 200 characters'),
];

// A bad id gives a clear 400 instead of a database error.
const idRule = [param('id').isMongoId().withMessage('Invalid id')];

router.post('/', requireRole('recipient'), createRules, validate, claims.create);
// Named paths before "/:id/..." so they are never read as an id.
router.get('/mine', requireRole('recipient'), claims.mine);
router.get('/incoming', requireRole('donor'), claims.incoming);
router.patch('/:id/approve', requireRole('donor'), idRule, validate, claims.approve);
router.patch('/:id/reject', requireRole('donor'), idRule, validate, claims.reject);
router.patch('/:id/cancel', requireRole('recipient'), idRule, validate, claims.cancel);

module.exports = router;
