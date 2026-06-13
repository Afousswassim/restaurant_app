const mongoose = require('mongoose');

const branchSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
      slug: {
        type: String,
        required: true,
        trim: true,
        unique: true,
        lowercase: true,
      },
    address: {
      type: String,
      required: true,
    },
    deliveryFee: {
      type: Number,
      required: true,
      min: 0,
    },
    deliveryTime: {
      type: String,
      required: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Branch', branchSchema, 'branches');
