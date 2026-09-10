const express = require('express');
const orderController = require('../controllers/orderController');
const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/', orderController.createOrder);
router.get('/:id', orderController.getOrder);
router.get('/', requireAuth, requireAdmin, orderController.getAllOrders);
router.put('/:id/status', requireAuth, requireAdmin, orderController.updateOrderStatus);

module.exports = router;

