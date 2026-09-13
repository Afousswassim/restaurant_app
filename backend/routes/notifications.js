const express = require('express');
const notificationController = require('../controllers/notificationController');
const { requireAuth } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/:clientId', requireAuth, notificationController.getNotifications);
router.post('/', notificationController.createNotification);
router.put('/:id/read', requireAuth, notificationController.markAsRead);
router.put('/:clientId/read-all', requireAuth, notificationController.markAllAsRead);

module.exports = router;