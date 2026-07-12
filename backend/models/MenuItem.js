const mongoose = require('mongoose');

const menuItemSchema = new mongoose.Schema(
  {
    branchId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Branch',
      required: false,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    hasOffer: {
      type: Boolean,
      default: false,
    },
    oldPrice: {
      type: Number,
    },
    offerPrice: {
      type: Number,
    },
    offerTitle: {
      type: String,
    },
    offerDescription: {
      type: String,
    },
    offerStartDate: {
      type: Date,
    },
    offerExpiresAt: {
      type: Date,
    },
    offerLabel: {
      type: String,
    },
    isOfferActive: {
      type: Boolean,
      default: false,
    },
    imageUrl: {
      type: String,
      required: true,
    },
    category: {
      type: String,
      required: true,
    },
    calories: {
      type: Number,
      default: 0,
      min: 0,
    },
    protein: {
      type: Number,
      default: 0,
      min: 0,
    },
    carbs: {
      type: Number,
      default: 0,
      min: 0,
    },
    fat: {
      type: Number,
      default: 0,
      min: 0,
    },
    tags: {
      type: [String],
      default: [],
    },
    extras: [
      {
        name: {
          type: String,
          required: true,
        },
        price: {
          type: Number,
          required: true,
        },
      },
    ],
    isAvailable: {
      type: Boolean,
      default: true,
    },
    rating: {
      type: Number,
      default: 4.5,
      min: 0,
      max: 5,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('MenuItem', menuItemSchema, 'menu_items');
