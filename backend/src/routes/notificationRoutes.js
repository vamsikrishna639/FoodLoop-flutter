const express = require('express');
const { param } = require('express-validator');
const validate = require('../middleware/validate');
const { protect, requireApproved } = require('../middleware/auth');
const notifications = require('../controllers/notificationController');

const router = express.Router();

// Any approved account, for its own notifications only.
router.use(protect, requireApproved);

router.get('/', notifications.list);
// "/read-all" before "/:id/read" for readability (the paths differ anyway).
router.patch('/read-all', notifications.markAllRead);
router.patch('/:id/read', [param('id').isMongoId().withMessage('Invalid id')], validate, notifications.markRead);

module.exports = router;
