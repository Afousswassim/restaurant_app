const express = require('express');
const orderController = require('../controllers/orderController');
const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');

const router = express.Router();

// Public route to create order
router.post('/', orderController.createOrder);

// Authenticated client route to get own orders (MUST be placed before /:id)
router.get('/my-orders', requireAuth, orderController.getMyOrders);

// Public route to get single order by ID
router.get('/:id', orderController.getOrder);

// Admin route to get all orders
router.get('/', requireAuth, requireAdmin, orderController.getAllOrders);

// Admin route to update order status
router.put('/:id/status', requireAuth, requireAdmin, orderController.updateOrderStatus);

module.exports = router;

