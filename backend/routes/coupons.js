const express = require('express');
const couponController = require('../controllers/couponController');

const router = express.Router();

router.get('/', couponController.getCoupons);
router.post('/validate', couponController.validateCoupon);

module.exports = router;
