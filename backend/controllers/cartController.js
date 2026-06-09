const CartItem = require('../models/CartItem');
const MenuItem = require('../models/MenuItem');

exports.getCart = async (req, res) => {
  try {
    const { sessionId } = req.query;
    if (!sessionId) {
      return res.status(400).json({
        success: false,
        message: 'Session ID is required',
      });
    }

    const items = await CartItem.find({ sessionId }).populate('menuItemId');
    
    // Filter out items whose menuItem no longer exists
    const validItems = items.filter(item => item.menuItemId);

    res.status(200).json({
      success: true,
      data: validItems,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.addToCart = async (req, res) => {
  try {
    const { sessionId, menuItemId, branchId, quantity, selectedExtras = [] } = req.body;

    if (!sessionId || !menuItemId || !branchId || !quantity) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
      });
    }

    const menuItem = await MenuItem.findById(menuItemId);
    if (!menuItem) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    // Find if the same item with the same extras already exists in this session
    const existingItems = await CartItem.find({ sessionId, menuItemId, branchId });

    const isSameExtras = (extrasA, extrasB) => {
      if (extrasA.length !== extrasB.length) return false;
      const sortedA = [...extrasA].sort((a, b) => a.name.localeCompare(b.name));
      const sortedB = [...extrasB].sort((a, b) => a.name.localeCompare(b.name));
      return sortedA.every((extra, idx) => extra.name === sortedB[idx].name && extra.price === sortedB[idx].price);
    };

    const matchedItem = existingItems.find(item => isSameExtras(item.selectedExtras, selectedExtras));

    if (matchedItem) {
      matchedItem.quantity += quantity;
      await matchedItem.save();
    } else {
      await CartItem.create({
        sessionId,
        menuItemId,
        branchId,
        quantity,
        selectedExtras,
      });
    }

    const updatedItems = await CartItem.find({ sessionId }).populate('menuItemId');
    res.status(200).json({
      success: true,
      data: updatedItems.filter(item => item.menuItemId),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.updateCartItem = async (req, res) => {
  try {
    const { sessionId, quantity } = req.body;
    const cartItemId = req.params.id;

    if (!sessionId) {
      return res.status(400).json({
        success: false,
        message: 'Session ID is required',
      });
    }

    // Attempt to find by cart item document _id first
    let cartItem = await CartItem.findOne({ _id: cartItemId, sessionId });

    // Fallback: if not found (e.g. legacy frontend request sending menuItemId), find by menuItemId
    if (!cartItem) {
      cartItem = await CartItem.findOne({ menuItemId: cartItemId, sessionId });
    }

    if (!cartItem) {
      return res.status(404).json({
        success: false,
        message: 'Cart item not found',
      });
    }

    if (quantity <= 0) {
      await CartItem.deleteOne({ _id: cartItem._id });
    } else {
      cartItem.quantity = quantity;
      await cartItem.save();
    }

    const updatedItems = await CartItem.find({ sessionId }).populate('menuItemId');
    res.status(200).json({
      success: true,
      data: updatedItems.filter(item => item.menuItemId),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.removeFromCart = async (req, res) => {
  try {
    const sessionId = req.body.sessionId || req.query.sessionId;
    const cartItemId = req.params.id;

    if (!sessionId) {
      return res.status(400).json({
        success: false,
        message: 'Session ID is required',
      });
    }

    // Try finding by _id first, then by menuItemId as fallback
    let cartItem = await CartItem.findOne({ _id: cartItemId, sessionId });
    if (!cartItem) {
      cartItem = await CartItem.findOne({ menuItemId: cartItemId, sessionId });
    }

    if (!cartItem) {
      return res.status(404).json({
        success: false,
        message: 'Cart item not found',
      });
    }

    await CartItem.deleteOne({ _id: cartItem._id });

    const updatedItems = await CartItem.find({ sessionId }).populate('menuItemId');
    res.status(200).json({
      success: true,
      data: updatedItems.filter(item => item.menuItemId),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.clearCart = async (req, res) => {
  try {
    const sessionId = req.body.sessionId || req.query.sessionId;

    if (!sessionId) {
      return res.status(400).json({
        success: false,
        message: 'Session ID is required',
      });
    }

    await CartItem.deleteMany({ sessionId });

    res.status(200).json({
      success: true,
      data: [],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
