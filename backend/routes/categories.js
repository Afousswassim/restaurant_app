const express = require('express');
const categoryController = require('../controllers/categoryController');
const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', categoryController.getCategories);
router.post('/', requireAuth, requireAdmin, categoryController.createCategory);
router.put('/:id', requireAuth, requireAdmin, categoryController.updateCategory);
router.delete('/:id', requireAuth, requireAdmin, categoryController.deleteCategory);

module.exports = router;

