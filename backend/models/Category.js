const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    description: {
      type: String,
      default: '',
    },
    image: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      default: 'fastfood',
    },
    status: {
      type: String,
      enum: ['Active', 'Inactive', 'Hidden', 'Empty'],
      default: 'Active',
    },
    sortOrder: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Category', categorySchema, 'categories');
