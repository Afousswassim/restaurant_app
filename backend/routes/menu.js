const express = require('express');
const menuController = require('../controllers/menuController');
const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');

const router = express.Router();

// Public read routes
router.get('/', menuController.getMenu);
router.get('/:branchId', menuController.getMenuByBranch);
router.get('/item/:id', menuController.getMenuItemById);

// Protected admin write routes
router.post('/', requireAuth, requireAdmin, menuController.createMenuItem);
router.put('/:id', requireAuth, requireAdmin, menuController.updateMenuItem);
router.delete('/:id', requireAuth, requireAdmin, menuController.deleteMenuItem);
router.put('/:id/offer', requireAuth, requireAdmin, menuController.updateMenuItemOffer);
router.delete('/:id/offer', requireAuth, requireAdmin, menuController.deleteMenuItemOffer);

module.exports = router;

