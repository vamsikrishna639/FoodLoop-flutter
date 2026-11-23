const express = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { protect } = require('../middleware/auth');
const auth = require('../controllers/authController');

const router = express.Router();

router.post(
  '/register',
  [
    body('name').trim().isLength({ min: 2 }).withMessage('Enter your name'),
    body('email').trim().isEmail().withMessage('Enter a valid email').toLowerCase(),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    // "admin" is deliberately missing: admins are only created by the seed script.
    body('role').isIn(['donor', 'recipient', 'volunteer']).withMessage('Choose donor, recipient or volunteer'),
    body('phone').trim().matches(/^[0-9+\- ]{7,15}$/).withMessage('Enter a valid phone number'),
    body('organization').optional().trim().isLength({ max: 80 }).withMessage('Organization name is too long'),
  ],
  validate,
  auth.register
);

router.post(
  '/login',
  [
    body('email').trim().isEmail().withMessage('Enter a valid email').toLowerCase(),
    body('password').notEmpty().withMessage('Enter your password'),
  ],
  validate,
  auth.login
);

router.get('/me', protect, auth.me);

module.exports = router;
