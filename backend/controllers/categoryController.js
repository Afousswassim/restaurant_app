const Category = require('../models/Category');
const MenuItem = require('../models/MenuItem');

exports.getCategories = async (req, res) => {
  try {
    const categories = await Category.find({ status: { $nin: ['Inactive', 'Hidden', 'Empty'] } }).sort({ sortOrder: 1, name: 1 });
    const data = [];
    for (const cat of categories) {
      const productCount = await MenuItem.countDocuments({ category: cat.name });
      data.push({
        _id: cat._id.toString(),
        id: cat._id.toString(),
        name: cat.name,
        description: cat.description || '',
        image: cat.image || '',
        icon: cat.icon || 'fastfood',
        status: cat.status || 'Active',
        sortOrder: cat.sortOrder || 0,
        createdAt: cat.createdAt,
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
    const { name, description = '', image = '', icon = 'fastfood', status = 'Active', sortOrder = 0 } = req.body;
    if (!name || !name.toString().trim()) {
      return res.status(400).json({
        success: false,
        message: 'Category name is required',
      });
    }
    const category = await Category.create({
      name: name.toString().trim(),
      description: description?.toString() || '',
      image: image?.toString() || '',
      icon: icon?.toString() || 'fastfood',
      status: status?.toString() || 'Active',
      sortOrder: Number(sortOrder || 0),
    });
    const payload = category.toObject();
    res.status(201).json({
      success: true,
      data: { ...payload, id: payload._id.toString(), _id: payload._id.toString() },
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
    const updates = { ...req.body };
    if (!updates.name || !updates.name.toString().trim()) {
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
    const updatedCategory = await Category.findByIdAndUpdate(id, updates, { new: true });
    if (updates.name && updates.name !== oldCategory.name) {
      await MenuItem.updateMany({ category: oldCategory.name }, { category: updates.name });
    }
    const payload = updatedCategory.toObject();
    res.status(200).json({
      success: true,
      data: { ...payload, id: payload._id.toString(), _id: payload._id.toString() },
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
    const linkedProducts = await MenuItem.find({ category: category.name });
    if (linkedProducts.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Category has products. Move them first or delete from admin panel.',
      });
    }
    await Category.findByIdAndDelete(id);
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
