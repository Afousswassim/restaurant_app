const Order = require('../models/Order');
const CartItem = require('../models/CartItem');

exports.createOrder = async (req, res) => {
  try {
    const { sessionId, customerName, phone, address, branch, paymentMethod, notes } = req.body;

    if (!sessionId || !customerName || !phone || !address || !branch) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
      });
    }

    const cartItems = await CartItem.find({ sessionId }).populate('menuItemId');
    if (cartItems.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Cart is empty',
      });
    }

    let subtotal = 0;
    const items = cartItems.map((item) => {
      const extrasCost = item.selectedExtras.reduce((sum, extra) => sum + extra.price, 0);
      const itemPrice = item.menuItemId.price + extrasCost;
      const totalItemCost = itemPrice * item.quantity;
      subtotal += totalItemCost;

      return {
        menuItemId: item.menuItemId._id,
        name: item.menuItemId.name,
        quantity: item.quantity,
        price: item.menuItemId.price,
        selectedExtras: item.selectedExtras,
      };
    });

    const deliveryFee = Number(branch.deliveryFee) || 0;
    const totalAmount = subtotal + deliveryFee;

    const order = await Order.create({
      customerName,
      phone,
      address,
      branch: {
        id: branch.id || branch._id,
        name: branch.name,
        address: branch.address,
        deliveryFee: deliveryFee,
        deliveryTime: branch.deliveryTime,
      },
      items,
      subtotal,
      deliveryFee,
      totalAmount,
      status: 'pending',
      paymentMethod: paymentMethod || 'cash',
      notes: notes || '',
    });

    // Clear cart for the session
    await CartItem.deleteMany({ sessionId });

    res.status(201).json({
      success: true,
      data: order,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getOrder = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }
    res.status(200).json({
      success: true,
      data: order,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getAllOrders = async (req, res) => {
  try {
    const orders = await Order.find().sort({ createdAt: -1 }).limit(50);
    res.status(200).json({
      success: true,
      data: orders,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.updateOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required',
      });
    }

    const order = await Order.findByIdAndUpdate(id, { status }, { new: true });
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    // Hook for client notifications on status change (to be implemented later)
    // Example: notifyClientOfStatusChange(order);

    res.status(200).json({
      success: true,
      data: order,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
