const Coupon = require('../models/Coupon');
const Client = require('../models/Client');

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

    // Check database coupons (reward coupons)
    const dbCoupon = await Coupon.findOne({ code: cleanCode, isUsed: false });
    if (!dbCoupon) {
      return res.status(404).json({
        success: false,
        message: 'Invalid, used, or expired coupon code',
      });
    }

    let discount = 0;
    if (dbCoupon.discountType === 'percentage') {
      discount = Number((subtotal * (dbCoupon.value / 100)).toFixed(2));
    } else if (dbCoupon.discountType === 'fixed') {
      discount = Math.min(dbCoupon.value, subtotal);
    } else if (dbCoupon.discountType === 'free_delivery') {
      discount = 0; // checkout overrides delivery fee
    }

    res.status(200).json({
      success: true,
      data: {
        code: dbCoupon.code,
        discountType: dbCoupon.discountType,
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

exports.redeemReward = async (req, res) => {
  try {
    const { clientId, rewardType } = req.body;
    if (!clientId || !rewardType) {
      return res.status(400).json({
        success: false,
        message: 'clientId and rewardType are required',
      });
    }

    const client = await Client.findById(clientId);
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    let pointsRequired = 0;
    let rewardValue = 0;

    if (rewardType === 'drink') {
      pointsRequired = 300;
      rewardValue = 18; // value in DH
    } else if (rewardType === 'burger') {
      pointsRequired = 500;
      rewardValue = 55; // value in DH
    } else if (rewardType === 'meal') {
      pointsRequired = 1000;
      rewardValue = 120; // value in DH
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid reward type. Choose drink, burger, or meal',
      });
    }

    if ((client.loyaltyPoints || 0) < pointsRequired) {
      return res.status(400).json({
        success: false,
        message: 'Not enough points',
      });
    }

    // Deduct points
    client.loyaltyPoints = (client.loyaltyPoints || 0) - pointsRequired;
    await client.save();

    // Create unique reward coupon
    const randStr = Math.random().toString(36).substring(2, 6).toUpperCase();
    const couponCode = `REWARD_${rewardType.toUpperCase()}_${randStr}`;

    const coupon = await Coupon.create({
      code: couponCode,
      discountType: 'fixed',
      value: rewardValue,
      clientId: client._id,
    });

    const clientData = client.toObject();
    delete clientData.password;

    res.status(200).json({
      success: true,
      message: 'Reward redeemed successfully!',
      data: {
        client: clientData,
        coupon: {
          code: couponCode,
          value: rewardValue,
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
