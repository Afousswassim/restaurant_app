const Category = require('../models/Category');
const MenuItem = require('../models/MenuItem');

exports.getCategories = async (req, res) => {
  try {
    const categories = await Category.find({}).sort({ name: 1 });
    const data = [];
    for (const cat of categories) {
      const productCount = await MenuItem.countDocuments({ category: cat.name });
      data.push({
        _id: cat._id,
        name: cat.name,
        productCount,
      });
    }
    res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.createCategory = async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Category name is required',
      });
    }
    const category = await Category.create({ name });
    res.status(201).json({
      success: true,
      data: category,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Category name is required',
      });
    }
    const oldCategory = await Category.findById(id);
    if (!oldCategory) {
      return res.status(404).json({
        success: false,
        message: 'Category not found',
      });
    }
    const updatedCategory = await Category.findByIdAndUpdate(id, { name }, { new: true });
    // Cascade update to MenuItems
    await MenuItem.updateMany({ category: oldCategory.name }, { category: name });
    res.status(200).json({
      success: true,
      data: updatedCategory,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.deleteCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const category = await Category.findById(id);
    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found',
      });
    }
    await Category.findByIdAndDelete(id);
    // Cascade uncategorize to MenuItems
    await MenuItem.updateMany({ category: category.name }, { category: 'Uncategorized' });
    res.status(200).json({
      success: true,
      message: 'Category deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
