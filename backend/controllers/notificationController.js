const mongoose = require('mongoose');
const Notification = require('../models/Notification');

exports.getNotifications = async (req, res) => {
  try {
    const rawId = req.params.clientId;
    const authUserId = req.user?.userId || req.user?.id;
    const targetClientId = (rawId && rawId !== 'me') ? rawId : authUserId;

    if (!targetClientId || !mongoose.Types.ObjectId.isValid(targetClientId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or missing Client ID',
      });
    }

    if (req.user && req.user.role === 'client' && authUserId !== targetClientId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: Cannot view notifications of another client',
      });
    }

    const notifications = await Notification.find({ clientId: targetClientId })
      .sort({ createdAt: -1 })
      .limit(100);

    res.status(200).json({
      success: true,
      data: notifications,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.createNotification = async (req, res) => {
  try {
    const { clientId, orderId, title, message, isRead } = req.body;
    if (!clientId || !title || !message) {
      return res.status(400).json({
        success: false,
        message: 'Missing required notification fields',
      });
    }

    if (!mongoose.Types.ObjectId.isValid(clientId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid Client ID format',
      });
    }

    const validOrderId = (orderId && mongoose.Types.ObjectId.isValid(orderId)) ? orderId : null;

    const notification = await Notification.create({
      clientId,
      orderId: validOrderId,
      title,
      message,
      isRead: isRead ?? false,
    });

    res.status(201).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    if (!id || !mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid Notification ID format',
      });
    }

    const notification = await Notification.findByIdAndUpdate(
      id,
      { isRead: true },
      { new: true }
    );
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    res.status(200).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    const rawId = req.params.clientId;
    const authUserId = req.user?.userId || req.user?.id;
    const targetClientId = (rawId && rawId !== 'me') ? rawId : authUserId;

    if (!targetClientId || !mongoose.Types.ObjectId.isValid(targetClientId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid Client ID format',
      });
    }

    const result = await Notification.updateMany(
      { clientId: targetClientId, isRead: false },
      { isRead: true }
    );

    res.status(200).json({
      success: true,
      data: { modifiedCount: result.modifiedCount ?? result.nModified ?? 0 },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};