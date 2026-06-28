const express = require('express');
const loyaltyController = require('../controllers/loyaltyController');

const router = express.Router();

router.post('/redeem', loyaltyController.redeemReward);

module.exports = router;
