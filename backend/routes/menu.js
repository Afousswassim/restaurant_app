const express = require('express');
const menuController = require('../controllers/menuController');

const router = express.Router();

router.get('/', menuController.getMenu);
router.get('/:branchId', menuController.getMenuByBranch);
router.get('/item/:id', menuController.getMenuItemById);
router.post('/', menuController.createMenuItem);

module.exports = router;
