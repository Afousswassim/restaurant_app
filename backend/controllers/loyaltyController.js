const mongoose = require('mongoose');
const Client = require('../models/Client');
const Order = require('../models/Order');

const rewards = {
  drink: {
    type: 'drink',
    name: 'Free Drink',
    pointsRequired: 300,
    value: 18,
  },
  burger: {
    type: 'burger',
    name: 'Free Burger',
    pointsRequired: 500,
    value: 55,
  },
  meal: {
    type: 'meal',
    name: 'Free Meal',
    pointsRequired: 1000,
    value: 120,
  },
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

    if (!mongoose.Types.ObjectId.isValid(clientId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid clientId',
      });
    }

    const reward = rewards[rewardType];
    if (!reward) {
      return res.status(400).json({
        success: false,
        message: 'Invalid reward type. Choose drink, burger, or meal',
      });
    }

    const client = await Client.findById(clientId);
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    const currentPoints = Number(client.loyaltyPoints) || 0;
    if (currentPoints < reward.pointsRequired) {
      return res.status(400).json({
        success: false,
        message: 'Not enough points',
      });
    }

    client.loyaltyPoints = currentPoints - reward.pointsRequired;
    await client.save();

    const rewardOrder = await Order.create({
      clientId: client._id,
      customerName: client.fullName,
      phone: client.phone,
      address: client.address || 'Reward redemption',
      branch: {
        id: 'reward',
        name: 'Loyalty Rewards',
        address: '',
        deliveryFee: 0,
        deliveryTime: '',
      },
      items: [
        {
          name: reward.name,
          quantity: 1,
          price: 0,
          originalPrice: reward.value,
          finalPrice: 0,
          offerApplied: false,
          selectedExtras: [],
        },
      ],
      subtotal: 0,
      deliveryFee: 0,
      totalAmount: 0,
      status: 'reward_redeemed',
      paymentMethod: 'points',
      notes: `Points used: ${reward.pointsRequired} pts`,
      orderType: 'reward',
      pointsUsed: reward.pointsRequired,
      rewardName: reward.name,
    });

    const clientData = client.toObject();
    delete clientData.password;

    res.status(200).json({
      success: true,
      message: 'Reward redeemed successfully!',
      data: {
        client: clientData,
        reward,
        order: rewardOrder,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
