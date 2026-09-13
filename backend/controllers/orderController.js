const Order = require('../models/Order');
const CartItem = require('../models/CartItem');
const Notification = require('../models/Notification');
const Client = require('../models/Client');

exports.createOrder = async (req, res) => {
  try {
    const { sessionId, customerName, phone, address, branch, paymentMethod, notes, clientId, discount, couponCode } = req.body;

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
      const menuItem = item.menuItemId;
      const isActiveOffer = menuItem.hasOffer && (!menuItem.offerExpiresAt || new Date() < new Date(menuItem.offerExpiresAt));
      const effectivePrice = isActiveOffer ? menuItem.offerPrice : menuItem.price;

      const extrasCost = item.selectedExtras.reduce((sum, extra) => sum + extra.price, 0);
      const itemPrice = effectivePrice + extrasCost;
      const totalItemCost = itemPrice * item.quantity;
      subtotal += totalItemCost;

      return {
        menuItemId: menuItem._id,
        name: menuItem.name,
        quantity: item.quantity,
        price: effectivePrice, // For backward compatibility
        originalPrice: menuItem.price,
        finalPrice: effectivePrice,
        offerApplied: isActiveOffer,
        selectedExtras: item.selectedExtras,
      };
    });

    const deliveryFee = Number(branch.deliveryFee) || 0;
    const appliedDiscount = Number(discount) || 0;
    const totalAmount = Math.max(0, subtotal + deliveryFee - appliedDiscount);

    const order = await Order.create({
      clientId: clientId || null,
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
      discount: appliedDiscount,
      couponCode: couponCode || '',
      totalAmount,
      status: 'pending',
      paymentMethod: paymentMethod || 'cash',
      notes: notes || '',
    });

    // Clear cart for the session
    await CartItem.deleteMany({ sessionId });

    // Update Client Loyalty Points (1 point per 1 DH spent on total amount)
    if (clientId) {
      const client = await Client.findById(clientId);
      if (client) {
        client.loyaltyPoints = (client.loyaltyPoints || 0) + Math.round(totalAmount);
        await client.save();
      }

      // Create initial notification for the client
      try {
        const shortId = order._id.toString().slice(-6).toUpperCase();
        await Notification.create({
          clientId: order.clientId,
          orderId: order._id,
          title: 'Commande enregistrée',
          message: `Votre commande #${shortId} a été enregistrée avec succès.`,
          isRead: false,
        });
      } catch (notifErr) {
        console.error('Error creating initial order notification:', notifErr);
      }
    }

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

exports.getMyOrders = async (req, res) => {
  try {
    const clientId = req.user?.userId || req.user?.id;
    if (!clientId) {
      return res.status(400).json({
        success: false,
        message: 'Client ID missing from authentication token',
      });
    }

    const orders = await Order.find({ clientId }).sort({ createdAt: -1 }).limit(50);
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
    const filter = {};
    if (req.query.clientId) {
      filter.clientId = req.query.clientId;
    }
    const orders = await Order.find(filter).sort({ createdAt: -1 }).limit(50);
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

    const statusLabels = {
      pending: 'Commande en attente',
      preparing: 'Commande en préparation',
      delivering: 'Commande en cours de livraison',
      delivered: 'Commande livrée',
      cancelled: 'Commande annulée',
    };

    const statusMessages = {
      pending: (shortId) => `Votre commande #${shortId} est en attente de confirmation.`,
      preparing: (shortId) => `Votre commande #${shortId} est en cours de préparation.`,
      delivering: (shortId) => `Votre commande #${shortId} est en cours de livraison.`,
      delivered: (shortId) => `Votre commande #${shortId} a été livrée avec succès. Bonne dégustation !`,
      cancelled: (shortId) => `Votre commande #${shortId} a été annulée.`,
    };

    const notifyStatuses = ['pending', 'preparing', 'delivering', 'delivered', 'cancelled'];
    const normalizedStatus = (status || '').toLowerCase();

    if (order.clientId && notifyStatuses.includes(normalizedStatus)) {
      const shortId = order._id.toString().slice(-6).toUpperCase();
      const title = statusLabels[normalizedStatus] || `Statut de la commande mis à jour`;
      const messageBuilder = statusMessages[normalizedStatus];
      const message = messageBuilder ? messageBuilder(shortId) : `Votre commande #${shortId} est maintenant ${status}.`;

      try {
        await Notification.create({
          clientId: order.clientId,
          orderId: order._id,
          title,
          message,
          isRead: false,
        });
      } catch (notifErr) {
        console.error('Error creating status update notification:', notifErr);
      }
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
