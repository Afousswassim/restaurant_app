const Client = require('../models/Client');
const Order = require('../models/Order');
const MenuItem = require('../models/MenuItem');
const Category = require('../models/Category');
const crypto = require('crypto');

function hashPassword(password) {
  return crypto.createHash('sha256').update(password).digest('hex');
}

/**
 * Admin authentication controller.
 * Handles simple backend login for administrative portal.
 */

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
    }

    if (email === 'admin@wassimfood.com' && password === 'admin123') {
      return res.status(200).json({
        success: true,
        token: 'simple-admin-token',
        admin: {
          email: 'admin@wassimfood.com',
          name: 'Admin Wassim Food',
        },
      });
    } else {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Internal server error during login',
    });
  }
};

exports.getCustomers = async (req, res) => {
  try {
    const clients = await Client.find().sort({ createdAt: -1 }).lean();

    const menuItems = await MenuItem.find().lean();
    const itemCategoryMap = {};
    menuItems.forEach((item) => {
      itemCategoryMap[item._id.toString()] = item.category;
    });

    const orders = await Order.find({ clientId: { $in: clients.map((c) => c._id) } }).sort({ createdAt: -1 }).lean();

    const clientOrdersMap = {};
    orders.forEach((order) => {
      if (!order.clientId) return;
      const cid = order.clientId.toString();
      if (!clientOrdersMap[cid]) {
        clientOrdersMap[cid] = [];
      }
      clientOrdersMap[cid].push(order);
    });

    const customers = clients.map((client) => {
      const clientId = client._id.toString();
      const clientOrders = clientOrdersMap[clientId] || [];
      const totalOrders = clientOrders.length;
      const totalSpent = clientOrders.reduce((sum, o) => sum + (o.totalAmount || 0), 0);
      const lastOrder = clientOrders.length > 0 ? clientOrders[0].createdAt : null;

      const productCounts = {};
      const categoryCounts = {};
      clientOrders.forEach((order) => {
        (order.items || []).forEach((item) => {
          const name = item.name;
          const qty = item.quantity || 1;
          productCounts[name] = (productCounts[name] || 0) + qty;

          if (item.menuItemId) {
            const cat = itemCategoryMap[item.menuItemId.toString()];
            if (cat) {
              categoryCounts[cat] = (categoryCounts[cat] || 0) + qty;
            }
          }
        });
      });

      let favoriteProduct = '';
      let maxProductQty = 0;
      Object.keys(productCounts).forEach((name) => {
        if (productCounts[name] > maxProductQty) {
          maxProductQty = productCounts[name];
          favoriteProduct = name;
        }
      });

      let favoriteCategory = '';
      let maxCategoryQty = 0;
      Object.keys(categoryCounts).forEach((cat) => {
        if (categoryCounts[cat] > maxCategoryQty) {
          maxCategoryQty = categoryCounts[cat];
          favoriteCategory = cat;
        }
      });

      return {
        id: client._id,
        _id: client._id,
        fullName: client.fullName,
        name: client.fullName,
        phone: client.phone,
        email: client.email,
        address: client.address || '',
        city: client.city || '',
        avatar: client.avatar || '',
        loyaltyPoints: client.loyaltyPoints || 0,
        rewardPoints: client.loyaltyPoints || 0,
        status: client.status || 'Active',
        createdAt: client.createdAt,
        lastLoginAt: client.lastLoginAt || null,
        lastLogin: client.lastLoginAt || null,
        totalOrders,
        totalSpent,
        favoriteProduct,
        favoriteCategory,
        lastOrder,
      };
    });

    return res.status(200).json({
      success: true,
      data: customers,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to fetch customers',
    });
  }
};

exports.getCustomerById = async (req, res) => {
  try {
    const { id } = req.params;
    const client = await Client.findById(id).lean();
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found',
      });
    }

    const menuItems = await MenuItem.find().lean();
    const itemCategoryMap = {};
    menuItems.forEach((item) => {
      itemCategoryMap[item._id.toString()] = item.category;
    });

    const clientOrders = await Order.find({ clientId: client._id }).sort({ createdAt: -1 }).lean();

    const totalOrders = clientOrders.length;
    const completedOrders = clientOrders.filter((o) => o.status === 'delivered').length;
    const pendingOrders = clientOrders.filter((o) => o.status === 'pending').length;
    const preparingOrders = clientOrders.filter((o) => o.status === 'preparing').length;
    const deliveringOrders = clientOrders.filter((o) => o.status === 'delivering').length;
    const cancelledOrders = clientOrders.filter((o) => o.status === 'cancelled').length;
    const rewardPoints = client.loyaltyPoints || 0;
    const lifetimeSpending = clientOrders.reduce((sum, o) => sum + (o.totalAmount || 0), 0);
    const averageOrderValue = totalOrders > 0 ? (lifetimeSpending / totalOrders) : 0;
    const lastOrder = clientOrders.length > 0 ? clientOrders[0].createdAt : null;

    const productCounts = {};
    const categoryCounts = {};
    const productStats = {};

    clientOrders.forEach((order) => {
      (order.items || []).forEach((item) => {
        const name = item.name;
        const qty = item.quantity || 1;
        productCounts[name] = (productCounts[name] || 0) + qty;

        if (item.menuItemId) {
          const cat = itemCategoryMap[item.menuItemId.toString()];
          if (cat) {
            categoryCounts[cat] = (categoryCounts[cat] || 0) + qty;
          }
        }

        if (!productStats[name]) {
          productStats[name] = {
            name: name,
            quantity: 0,
            imageUrl: '',
          };
          const found = menuItems.find((mi) => mi.name === name || (item.menuItemId && mi._id.toString() === item.menuItemId.toString()));
          if (found) {
            productStats[name].imageUrl = found.imageUrl;
          }
        }
        productStats[name].quantity += qty;
      });
    });

    let favoriteProduct = '';
    let maxProductQty = 0;
    Object.keys(productCounts).forEach((name) => {
      if (productCounts[name] > maxProductQty) {
        maxProductQty = productCounts[name];
        favoriteProduct = name;
      }
    });

    let favoriteCategory = '';
    let maxCategoryQty = 0;
    Object.keys(categoryCounts).forEach((cat) => {
      if (categoryCounts[cat] > maxCategoryQty) {
        maxCategoryQty = categoryCounts[cat];
        favoriteCategory = cat;
      }
    });

    const favoriteProducts = Object.values(productStats)
      .sort((a, b) => b.quantity - a.quantity)
      .slice(0, 5);

    const rewardLevel = rewardPoints >= 800 ? 'Platinum' : rewardPoints >= 300 ? 'Gold' : 'Silver';
    const redeemedRewards = clientOrders.filter((o) => o.orderType === 'reward' || o.paymentMethod === 'points');

    return res.status(200).json({
      success: true,
      data: {
        customer: {
          id: client._id,
          _id: client._id,
          fullName: client.fullName,
          name: client.fullName,
          phone: client.phone,
          email: client.email,
          address: client.address || '',
          city: client.city || '',
          avatar: client.avatar || '',
          loyaltyPoints: client.loyaltyPoints || 0,
          rewardPoints: client.loyaltyPoints || 0,
          status: client.status || 'Active',
          createdAt: client.createdAt,
          lastLoginAt: client.lastLoginAt || null,
          lastLogin: client.lastLoginAt || null,
        },
        statistics: {
          totalOrders,
          completedOrders,
          pendingOrders,
          preparingOrders,
          deliveringOrders,
          cancelledOrders,
          rewardPoints,
          averageOrderValue,
          lifetimeSpending,
          favoriteCategory,
          favoriteProduct,
          lastOrder,
        },
        orderHistory: clientOrders,
        rewardSystem: {
          currentPoints: rewardPoints,
          rewardLevel,
          redeemedRewards,
        },
        favoriteProducts,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to fetch customer details',
    });
  }
};

exports.createCustomer = async (req, res) => {
  try {
    const { fullName, name, phone, email, password, address, city, avatar, status, loyaltyPoints, rewardPoints } = req.body;

    if (!fullName && !name) {
      return res.status(400).json({
        success: false,
        message: 'Name is required',
      });
    }

    if (!phone || !email) {
      return res.status(400).json({
        success: false,
        message: 'Phone and Email are required',
      });
    }

    const existingClient = await Client.findOne({ email });
    if (existingClient) {
      return res.status(400).json({
        success: false,
        message: 'Email already registered',
      });
    }

    const client = await Client.create({
      fullName: fullName || name,
      phone,
      email,
      password: hashPassword(password || 'customer123'),
      address: address || '',
      city: city || '',
      avatar: avatar || '',
      status: status || 'Active',
      loyaltyPoints: Number(loyaltyPoints || rewardPoints || 0),
    });

    const clientData = client.toObject();
    delete clientData.password;

    return res.status(201).json({
      success: true,
      data: clientData,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to create customer',
    });
  }
};

exports.updateCustomer = async (req, res) => {
  try {
    const { id } = req.params;
    const { fullName, name, phone, email, password, address, city, avatar, status, loyaltyPoints, rewardPoints } = req.body;

    const client = await Client.findById(id);
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found',
      });
    }

    if (email && email !== client.email) {
      const existingClient = await Client.findOne({ email });
      if (existingClient) {
        return res.status(400).json({
          success: false,
          message: 'Email already registered by another customer',
        });
      }
      client.email = email;
    }

    if (fullName !== undefined || name !== undefined) client.fullName = fullName || name;
    if (phone !== undefined) client.phone = phone;
    if (address !== undefined) client.address = address;
    if (city !== undefined) client.city = city;
    if (avatar !== undefined) client.avatar = avatar;
    if (status !== undefined) client.status = status;
    if (loyaltyPoints !== undefined || rewardPoints !== undefined) {
      client.loyaltyPoints = Number(loyaltyPoints !== undefined ? loyaltyPoints : rewardPoints);
    }

    if (password) {
      client.password = hashPassword(password);
    }

    await client.save();

    const clientData = client.toObject();
    delete clientData.password;

    return res.status(200).json({
      success: true,
      data: clientData,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to update customer',
    });
  }
};

exports.deleteCustomer = async (req, res) => {
  try {
    const { id } = req.params;
    const client = await Client.findByIdAndDelete(id);
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Customer deleted successfully',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to delete customer',
    });
  }
};

exports.updateCustomerStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['Active', 'Inactive', 'VIP', 'Blocked'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Status must be Active, Inactive, VIP or Blocked',
      });
    }

    const client = await Client.findByIdAndUpdate(
      id,
      { status },
      { new: true }
    ).lean();

    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found',
      });
    }

    return res.status(200).json({
      success: true,
      data: client,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to update customer status',
    });
  }
};

exports.updateCustomerVip = async (req, res) => {
  try {
    const { id } = req.params;
    const { vip, isVip, status } = req.body;

    let targetStatus = 'Active';
    if (vip === true || isVip === true || status === 'VIP') {
      targetStatus = 'VIP';
    } else if (vip === false || isVip === false) {
      targetStatus = 'Active';
    }

    const client = await Client.findByIdAndUpdate(
      id,
      { status: targetStatus },
      { new: true }
    ).lean();

    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found',
      });
    }

    return res.status(200).json({
      success: true,
      data: client,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to update customer VIP status',
    });
  }
};

exports.updateCustomerRewards = async (req, res) => {
  try {
    const { id } = req.params;
    const { action, points } = req.body;

    const client = await Client.findById(id);
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found',
      });
    }

    const currentPoints = client.loyaltyPoints || 0;
    const diffPoints = Number(points || 0);

    if (action === 'add') {
      client.loyaltyPoints = currentPoints + diffPoints;
    } else if (action === 'reset') {
      client.loyaltyPoints = 0;
    } else if (action === 'set') {
      client.loyaltyPoints = diffPoints;
    } else {
      client.loyaltyPoints = diffPoints;
    }

    await client.save();

    return res.status(200).json({
      success: true,
      data: client,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to update customer rewards',
    });
  }
};

// ==========================================
// CATEGORY MANAGEMENT LOGIC
// ==========================================

exports.getAdminCategories = async (req, res) => {
  try {
    let categories = await Category.find().sort({ sortOrder: 1, createdAt: -1 }).lean();
    const menuItems = await MenuItem.find().lean();
    const orders = await Order.find().lean();

    // MIGRATION SCRIPT: Restore missing categories from existing products
    if (categories.length === 0 && menuItems.length > 0) {
      const uniqueNames = [...new Set(menuItems.map((item) => item.category).filter(Boolean))];
      if (uniqueNames.length > 0) {
        const newCats = uniqueNames.map((name, index) => ({
          name,
          description: `Automatically restored category`,
          status: 'Active',
          icon: 'fastfood',
          sortOrder: index,
        }));
        await Category.insertMany(newCats);
        console.log(`[MIGRATION] Restored ${uniqueNames.length} categories.`);
        categories = await Category.find().sort({ sortOrder: 1, createdAt: -1 }).lean();
      }
    }

    const data = categories.map((cat) => {
      const catProducts = menuItems.filter((item) => item.category === cat.name);
      let totalSales = 0;
      let revenue = 0;

      orders.forEach((order) => {
        (order.items || []).forEach((orderItem) => {
          const isCatProduct = catProducts.some((p) => p.name === orderItem.name);
          if (isCatProduct) {
            const qty = orderItem.quantity || 1;
            totalSales += qty;
            revenue += (orderItem.price || 0) * qty;
          }
        });
      });

      return {
        ...cat,
        id: cat._id.toString(),
        _id: cat._id.toString(),
        productCount: catProducts.length,
        totalSales,
        revenue,
        averageRating: 4.5 + (Math.random() * 0.4),
      };
    });

    console.log(`getAdminCategories: returning ${data.length} categories`);
    res.status(200).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Debug helper: return raw categories (admin only)
exports.debugCategories = async (req, res) => {
  try {
    const categories = await Category.find().lean();
    res.status(200).json({ success: true, data: categories });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getAdminCategoryById = async (req, res) => {
  try {
    const { id } = req.params;
    const category = await Category.findById(id).lean();
    if (!category) {
      return res.status(404).json({ success: false, message: 'Category not found' });
    }
    res.status(200).json({ success: true, data: { ...category, id: category._id.toString(), _id: category._id.toString() } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createAdminCategory = async (req, res) => {
  try {
    const { name, description = '', image = '', icon = 'fastfood', status = 'Active', sortOrder = 0 } = req.body;
    if (!name || !name.toString().trim()) {
      return res.status(400).json({ success: false, message: 'Category name is required' });
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
    res.status(201).json({ success: true, data: { ...payload, id: payload._id.toString(), _id: payload._id.toString() } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateAdminCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const oldCategory = await Category.findById(id);
    if (!oldCategory) {
      return res.status(404).json({ success: false, message: 'Category not found' });
    }

    const updates = { ...req.body };
    if (typeof updates.status === 'string') {
      if (updates.status.toLowerCase() === 'hidden' || updates.status.toLowerCase() === 'empty') {
        updates.status = 'Inactive';
      } else if (updates.status.toLowerCase() === 'active') {
        updates.status = 'Active';
      } else {
        updates.status = 'Inactive';
      }
    }
    if (typeof updates.name === 'string' && updates.name.trim()) {
      updates.name = updates.name.trim();
    }
    if (typeof updates.description === 'string') {
      updates.description = updates.description;
    }
    if (typeof updates.image === 'string') {
      updates.image = updates.image;
    }
    if (typeof updates.icon === 'string') {
      updates.icon = updates.icon;
    }
    if (typeof updates.status === 'string') {
      updates.status = updates.status;
    }
    if (typeof updates.sortOrder === 'number') {
      updates.sortOrder = updates.sortOrder;
    }

    const updated = await Category.findByIdAndUpdate(id, updates, { new: true });

    if (updated && req.body.name && req.body.name !== oldCategory.name) {
      await MenuItem.updateMany({ category: oldCategory.name }, { category: req.body.name });
    }

    const payload = updated.toObject();
    res.status(200).json({ success: true, data: { ...payload, id: payload._id.toString(), _id: payload._id.toString() } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteAdminCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { moveToCategoryId } = req.body || {};
    const category = await Category.findById(id);
    if (!category) return res.status(404).json({ success: false, message: 'Category not found' });

    const linkedProducts = await MenuItem.find({ category: category.name });

    if (linkedProducts.length > 0 && !moveToCategoryId) {
      return res.status(409).json({ success: false, message: 'Category has products. Choose a destination category or move them first.' });
    }

    if (moveToCategoryId) {
      const destination = await Category.findById(moveToCategoryId);
      if (!destination) {
        return res.status(404).json({ success: false, message: 'Destination category not found' });
      }
      await MenuItem.updateMany({ category: category.name }, { category: destination.name });
    } else if (linkedProducts.length === 0) {
      await MenuItem.updateMany({ category: category.name }, { category: 'Uncategorized' });
    }

    await Category.findByIdAndDelete(id);

    res.status(200).json({ success: true, message: 'Category deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateAdminCategoryStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const normalizedStatus = status?.toString().toLowerCase() === 'active' ? 'Active' : 'Inactive';
    const updated = await Category.findByIdAndUpdate(id, { status: normalizedStatus }, { new: true });
    if (!updated) return res.status(404).json({ success: false, message: 'Category not found' });
    const payload = updated.toObject();
    res.status(200).json({ success: true, data: { ...payload, id: payload._id.toString(), _id: payload._id.toString() } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
