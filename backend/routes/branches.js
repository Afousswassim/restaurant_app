const express = require('express');
const branchController = require('../controllers/branchController');

const router = express.Router();

router.get('/', branchController.getBranches);
router.get('/:slug', branchController.getBranchBySlug);
router.get('/:id/qr', branchController.getBranchQR);
router.patch('/:id/qr', branchController.updateBranchQR);

module.exports = router;
