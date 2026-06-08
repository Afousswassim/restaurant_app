const mongoose = require('mongoose');

const restaurantSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
    },
    imageUrl: {
      type: String,
      required: true,
    },
    rating: {
      type: Number,
      default: 4.5,
      min: 0,
      max: 5,
    },
    deliveryTime: {
      type: Number,
      default: 30,
    },
    deliveryFee: {
      type: Number,
      default: 15,
    },
    minOrder: {
      type: Number,
      default: 50,
    },
    cuisine: {
      type: String,
      default: 'Mixed',
    },
    category: {
      type: String,
      default: 'Mixed',
    },
    averagePrice: {
      type: Number,
      default: 0,
    },
    isOpen: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Restaurant', restaurantSchema);
