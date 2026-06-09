const MenuItem = require('../models/MenuItem');

exports.getMenu = async (req, res) => {
  try {
    const items = await MenuItem.find({}).sort({ category: 1, name: 1 });
    res.status(200).json({
      success: true,
      data: items,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getMenuByBranch = async (req, res) => {
  try {
    const { branchId } = req.params;
    // Show items that are either branch-independent (no branchId or null) or belong specifically to this branch
    const items = await MenuItem.find({
      $or: [
        { branchId: { $exists: false } },
        { branchId: null },
        { branchId },
      ],
    }).sort({ category: 1, name: 1 });

    res.status(200).json({
      success: true,
      data: items,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getMenuItemById = async (req, res) => {
  try {
    const item = await MenuItem.findById(req.params.id);
    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }
    res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.createMenuItem = async (req, res) => {
  try {
    const { branchId, name, description, price, imageUrl, category, extras } = req.body;
    const item = await MenuItem.create({
      branchId,
      name,
      description,
      price,
      imageUrl,
      category,
      extras,
    });
    res.status(201).json({
      success: true,
      data: item,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
