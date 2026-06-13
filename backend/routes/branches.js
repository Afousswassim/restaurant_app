const express = require('express');
const branchController = require('../controllers/branchController');

const router = express.Router();

router.get('/', branchController.getBranches);
router.get('/:slug', branchController.getBranchBySlug);

module.exports = router;
