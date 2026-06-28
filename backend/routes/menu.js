const express = require('express');
const menuController = require('../controllers/menuController');

const router = express.Router();

router.get('/', menuController.getMenu);
router.get('/:branchId', menuController.getMenuByBranch);
router.get('/item/:id', menuController.getMenuItemById);
router.post('/', menuController.createMenuItem);
router.put('/:id', menuController.updateMenuItem);
router.delete('/:id', menuController.deleteMenuItem);
router.put('/:id/offer', menuController.updateMenuItemOffer);
router.delete('/:id/offer', menuController.deleteMenuItemOffer);

module.exports = router;
