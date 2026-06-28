const MenuItem = require('../models/MenuItem');

exports.getMenu = async (req, res) => {
  try {
    const { search, category } = req.query;
    const filter = {};
    if (search) {
      filter.name = { $regex: search, $options: 'i' };
    }
    if (category && category !== 'All') {
      filter.category = category;
    }
    const items = await MenuItem.find(filter).sort({ category: 1, name: 1 });
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
    const { branchId, name, description, price, imageUrl, category, extras, calories, protein, carbs, fat, tags, isAvailable } = req.body;
    const item = await MenuItem.create({
      branchId: branchId || null,
      name,
      description,
      price,
      imageUrl,
      category,
      extras: extras || [],
      calories: calories || 0,
      protein: protein || 0,
      carbs: carbs || 0,
      fat: fat || 0,
      tags: tags || [],
      isAvailable: isAvailable !== undefined ? isAvailable : true,
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

exports.updateMenuItem = async (req, res) => {
  try {
    const { id } = req.params;
    const { branchId, name, description, price, imageUrl, category, extras, calories, protein, carbs, fat, tags, isAvailable } = req.body;
    const item = await MenuItem.findByIdAndUpdate(
      id,
      {
        branchId: branchId || null,
        name,
        description,
        price,
        imageUrl,
        category,
        extras: extras || [],
        calories: calories || 0,
        protein: protein || 0,
        carbs: carbs || 0,
        fat: fat || 0,
        tags: tags || [],
        isAvailable: isAvailable !== undefined ? isAvailable : true,
      },
      { new: true }
    );
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

exports.deleteMenuItem = async (req, res) => {
  try {
    const { id } = req.params;
    const item = await MenuItem.findByIdAndDelete(id);
    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }
    res.status(200).json({
      success: true,
      message: 'Menu item deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.updateMenuItemOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const { offerPrice, discountPercentage, offerExpiresAt, isOfferActive } = req.body;

    const item = await MenuItem.findById(id);
    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    item.hasOffer = true;
    item.oldPrice = item.price;
    item.offerPrice = offerPrice;
    item.offerLabel = discountPercentage ? `${discountPercentage}% OFF` : 'SALE';
    item.offerExpiresAt = offerExpiresAt ? new Date(offerExpiresAt) : null;
    item.isOfferActive = isOfferActive !== undefined ? isOfferActive : true;

    await item.save();
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

exports.deleteMenuItemOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const item = await MenuItem.findById(id);
    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    item.hasOffer = false;
    item.oldPrice = undefined;
    item.offerPrice = undefined;
    item.offerLabel = undefined;
    item.offerExpiresAt = undefined;
    item.isOfferActive = false;

    await item.save();
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
