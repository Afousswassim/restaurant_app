const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  menuItemId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MenuItem',
    default: null,
  },
  name: {
    type: String,
    required: true,
  },
  quantity: {
    type: Number,
    required: true,
  },
  price: {
    type: Number,
    required: true,
  },
  originalPrice: {
    type: Number,
  },
  finalPrice: {
    type: Number,
  },
  offerApplied: {
    type: Boolean,
    default: false,
  },
  selectedExtras: [
    {
      name: String,
      price: Number,
    },
  ],
});

const orderSchema = new mongoose.Schema(
  {
    customerName: {
      type: String,
      required: true,
      trim: true,
    },
    phone: {
      type: String,
      required: true,
    },
    address: {
      type: String,
      required: true,
    },
    branch: {
      id: String,
      name: String,
      address: String,
      deliveryFee: Number,
      deliveryTime: String,
    },
    items: [orderItemSchema],
    subtotal: {
      type: Number,
      required: true,
    },
    deliveryFee: {
      type: Number,
      required: true,
    },
    totalAmount: {
      type: Number,
      required: true,
    },
    status: {
      type: String,
      default: 'pending',
    },
    paymentMethod: {
      type: String,
      default: 'cash',
    },
    notes: {
      type: String,
      default: '',
    },
    clientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Client',
      default: null,
    },
    discount: {
      type: Number,
      default: 0,
    },
    couponCode: {
      type: String,
      default: '',
    },
    orderType: {
      type: String,
      enum: ['order', 'reward'],
      default: 'order',
    },
    pointsUsed: {
      type: Number,
      default: 0,
    },
    rewardName: {
      type: String,
      default: '',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Order', orderSchema, 'orders');
