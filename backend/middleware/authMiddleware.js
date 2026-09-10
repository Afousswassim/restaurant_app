const jwt = require('jsonwebtoken');
const Client = require('../models/Client');

const JWT_SECRET = process.env.JWT_SECRET || 'wassim_food_secret_key_2026';

/**
 * Authentication Middleware: Extracts and verifies JWT from Authorization header
 */
const requireAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
      });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (err) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token',
      });
    }

    const { userId, role } = decoded;
    if (!userId || !role) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token payload',
      });
    }

    if (role === 'client') {
      const client = await Client.findById(userId);
      if (!client) {
        return res.status(401).json({
          success: false,
          message: 'Client account not found',
        });
      }

      if (client.status === 'Inactive' || client.status === 'Blocked') {
        return res.status(403).json({
          success: false,
          message: 'Access denied',
        });
      }

      req.client = client;
      req.user = {
        id: client._id.toString(),
        userId: client._id.toString(),
        role: 'client',
        email: client.email,
      };
    } else if (role === 'admin') {
      req.user = {
        id: userId,
        userId: userId,
        role: 'admin',
        email: decoded.email || 'admin@wassimfood.com',
      };
    } else {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Authentication failed',
    });
  }
};

/**
 * Role Middleware: Ensures authenticated user has Admin role
 */
const requireAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Access denied',
    });
  }
  next();
};

/**
 * Role Middleware: Ensures authenticated user has Client role
 */
const requireClient = (req, res, next) => {
  if (!req.user || req.user.role !== 'client') {
    return res.status(403).json({
      success: false,
      message: 'Access denied',
    });
  }
  next();
};

module.exports = {
  requireAuth,
  requireAdmin,
  requireClient,
};
