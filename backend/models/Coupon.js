const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema(
  {
    code: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
    },
    type: {
      type: String,
      enum: ['percentage', 'fixed', 'free_delivery'],
      required: true,
    },
    value: {
      type: Number,
      required: true,
    },
    minOrderAmount: {
      type: Number,
      default: 0,
    },
    applicableCategories: {
      type: [String],
      default: [],
    },
    applicableProductIds: {
      type: [mongoose.Schema.Types.ObjectId],
      ref: 'MenuItem',
      default: [],
    },
    applicableProductNames: {
      type: [String],
      default: [],
    },
    clientOnly: {
      type: Boolean,
      default: false,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    expiresAt: {
      type: Date,
      default: null,
    },
    isUsed: {
      type: Boolean,
      default: false,
    },
    clientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Client',
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Coupon', couponSchema, 'coupons');
