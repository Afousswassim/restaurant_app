const express = require('express');
const notificationController = require('../controllers/notificationController');

const router = express.Router();

router.get('/:clientId', notificationController.getNotifications);
router.post('/', notificationController.createNotification);
router.put('/:id/read', notificationController.markAsRead);
router.put('/:clientId/read-all', notificationController.markAllAsRead);

module.exports = router;