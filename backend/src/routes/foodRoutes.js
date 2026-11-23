const express = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { protect, requireApproved, requireRole } = require('../middleware/auth');
const foods = require('../controllers/foodController');

const router = express.Router();

// Every listing route needs a logged-in, approved account.
router.use(protect, requireApproved);

// Format checks for a listing. On create every field is required; on edit
// (PATCH) each field is optional but must still be valid when it is sent.
// The date rules (future, after prepared time) live in the controller.
function listingRules(isUpdate) {
  const field = (name) => (isUpdate ? body(name).optional() : body(name));
  const optionalText = (name) => body(name).optional({ values: 'null' });

  return [
    field('title').trim().isLength({ min: 2, max: 80 }).withMessage('Give the food a name (2 to 80 characters)'),
    optionalText('description').trim().isLength({ max: 500 }).withMessage('Keep the description under 500 characters'),
    field('quantity').isInt({ min: 1, max: 1000 }).withMessage('Quantity must be a whole number from 1 to 1000').toInt(),
    field('unit').isIn(['boxes', 'plates', 'kg', 'packets']).withMessage('Choose boxes, plates, kg or packets'),
    field('location').trim().isLength({ min: 2, max: 120 }).withMessage('Say where to collect it from'),
    field('preparedAt').isISO8601().withMessage('Enter when the food was prepared').toDate(),
    field('pickupDeadline').isISO8601().withMessage('Enter a pickup deadline').toDate(),
    field('foodType').isIn(['veg', 'non-veg', 'mixed']).withMessage('Choose veg, non-veg or mixed'),
    optionalText('allergenNotes').trim().isLength({ max: 300 }).withMessage('Keep allergen notes under 300 characters'),
    body('imageUrl')
      .optional({ values: 'falsy' })
      .trim()
      .isURL({ protocols: ['http', 'https'], require_protocol: true })
      .withMessage('Image link must start with http:// or https://'),
  ];
}

router.get('/', foods.list);
// "/mine" must come before "/:id", otherwise "mine" would be read as an id.
router.get('/mine', requireRole('donor'), foods.mine);
router.get('/:id', foods.getOne);
router.post('/', requireRole('donor'), listingRules(false), validate, foods.create);
router.patch('/:id', requireRole('donor', 'admin'), listingRules(true), validate, foods.update);
router.delete('/:id', requireRole('donor', 'admin'), foods.remove);

module.exports = router;
