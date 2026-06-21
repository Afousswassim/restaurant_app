const Notification = require('../models/Notification');

exports.getNotifications = async (req, res) => {
  try {
    const { clientId } = req.params;
    const notifications = await Notification.find({ clientId })
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
    if (!clientId || !orderId || !title || !message) {
      return res.status(400).json({
        success: false,
        message: 'Missing required notification fields',
      });
    }

    const notification = await Notification.create({
      clientId,
      orderId,
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
    const { clientId } = req.params;
    const result = await Notification.updateMany(
      { clientId, isRead: false },
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