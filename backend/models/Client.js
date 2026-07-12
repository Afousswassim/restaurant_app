const mongoose = require('mongoose');

const clientSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: true,
      trim: true,
    },
    phone: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      lowercase: true,
    },
    password: {
      type: String,
      required: true,
    },
    address: {
      type: String,
      default: '',
    },
    landmark: {
      type: String,
      default: '',
    },
    loyaltyPoints: {
      type: Number,
      default: 0,
    },
    status: {
      type: String,
      enum: ['Active', 'Inactive', 'VIP', 'Blocked'],
      default: 'Active',
    },
    city: {
      type: String,
      default: '',
    },
    avatar: {
      type: String,
      default: '',
    },
    lastLoginAt: {
      type: Date,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Client', clientSchema, 'clients');
