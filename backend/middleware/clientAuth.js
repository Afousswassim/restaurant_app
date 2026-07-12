const Client = require('../models/Client');

module.exports = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Authorization token required',
      });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token',
      });
    }

    let clientId;
    try {
      clientId = Buffer.from(token, 'base64').toString('ascii');
    } catch (e) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token encoding',
      });
    }

    const client = await Client.findById(clientId);
    if (!client) {
      return res.status(401).json({
        success: false,
        message: 'Client account not found',
      });
    }

    if (client.status === 'Inactive' || client.status === 'Blocked') {
      return res.status(403).json({
        success: false,
        message: 'Your account has been deactivated. Please contact support.',
      });
    }

    req.client = client;
    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Authentication failed',
    });
  }
};
