const express = require('express');
const Category = require('../models/Category');

const router = express.Router();

// Route: GET /categories
// Description: Public endpoint to get all Active categories
router.get('/', async (req, res) => {
  try {
    const categories = await Category.find({ status: 'Active' })
                                     .sort({ sortOrder: 1, createdAt: -1 })
                                     .lean();
    
    const data = categories.map((cat) => ({
      ...cat,
      id: cat._id.toString(),
      _id: cat._id.toString(),
    }));

    res.status(200).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
