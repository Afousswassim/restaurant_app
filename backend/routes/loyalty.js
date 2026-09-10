const express = require('express');
const loyaltyController = require('../controllers/loyaltyController');
const { requireAuth, requireClient } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/redeem', requireAuth, requireClient, loyaltyController.redeemReward);

module.exports = router;

