const Coupon = require('../models/Coupon');

exports.getCoupons = async (req, res) => {
  try {
    const { clientId } = req.query;
    const filter = { isUsed: false };
    if (clientId) {
      filter.clientId = clientId;
    }

    const dbCoupons = await Coupon.find(filter);
    res.status(200).json({
      success: true,
      data: dbCoupons,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.validateCoupon = async (req, res) => {
  try {
    const { code, subtotal } = req.body;
    if (!code) {
      return res.status(400).json({ success: false, message: 'Code is required' });
    }

    const cleanCode = code.trim().toUpperCase();

    // Check standard coupons first
    if (cleanCode === 'WELCOME20') {
      const discount = Number((subtotal * 0.2).toFixed(2));
      return res.status(200).json({
        success: true,
        data: {
          code: cleanCode,
          discountType: 'percentage',
          value: 20,
          discount,
        },
      });
    }

    if (cleanCode === 'BURGER50') {
      const discount = Math.min(50, subtotal);
      return res.status(200).json({
        success: true,
        data: {
          code: cleanCode,
          discountType: 'fixed',
          value: 50,
          discount,
        },
      });
    }

    if (cleanCode === 'BURGERDEAL') {
      const discount = Math.min(70, subtotal);
      return res.status(200).json({
        success: true,
        data: { code: cleanCode, discountType: 'fixed', value: 70, discount },
      });
    }

    if (cleanCode === 'PIZZADEAL') {
      const discount = Math.min(71, subtotal);
      return res.status(200).json({
        success: true,
        data: { code: cleanCode, discountType: 'fixed', value: 71, discount },
      });
    }

    if (cleanCode === 'CREPEDEAL') {
      const discount = Math.min(45, subtotal);
      return res.status(200).json({
        success: true,
        data: { code: cleanCode, discountType: 'fixed', value: 45, discount },
      });
    }

    if (cleanCode === 'FREESHIP') {
      if (subtotal < 150) {
        return res.status(400).json({
          success: false,
          message: 'Minimum subtotal of 150 DH is required for FREESHIP',
        });
      }

      return res.status(200).json({
        success: true,
        data: {
          code: cleanCode,
          discountType: 'free_delivery',
          value: 0,
          discount: 0,
        },
      });
    }

    // Check database coupons
    const dbCoupon = await Coupon.findOne({ code: cleanCode, isUsed: false });
    if (!dbCoupon) {
      return res.status(404).json({
        success: false,
        message: 'Invalid, used, or expired coupon code',
      });
    }

    const discountType = dbCoupon.type || dbCoupon.discountType;
    let discount = 0;
    if (discountType === 'percentage') {
      discount = Number((subtotal * (dbCoupon.value / 100)).toFixed(2));
    } else if (discountType === 'fixed') {
      discount = Math.min(dbCoupon.value, subtotal);
    } else if (discountType === 'free_delivery') {
      discount = 0; // checkout overrides delivery fee
    }

    res.status(200).json({
      success: true,
      data: {
        code: dbCoupon.code,
        discountType,
        value: dbCoupon.value,
        discount,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
