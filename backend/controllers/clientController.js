const Client = require('../models/Client');
const crypto = require('crypto');

function hashPassword(password) {
  return crypto.createHash('sha256').update(password).digest('hex');
}

exports.register = async (req, res) => {
  try {
    const { fullName, phone, email, password } = req.body;

    if (!fullName || !phone || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required',
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
      fullName,
      phone,
      email,
      password: hashPassword(password),
      status: 'Active',
    });

    const token = Buffer.from(client._id.toString()).toString('base64');

    // Return client without password
    const clientData = client.toObject();
    delete clientData.password;

    res.status(201).json({
      success: true,
      data: {
        token,
        client: clientData,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
    }

    const client = await Client.findOne({ email });
    if (!client) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    if (client.status === 'Inactive' || client.status === 'Blocked') {
      return res.status(403).json({
        success: false,
        message: 'Your account has been deactivated. Please contact support.',
      });
    }

    const hashedPassword = hashPassword(password);
    if (client.password !== hashedPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    client.lastLoginAt = new Date();
    await client.save();

    const token = Buffer.from(client._id.toString()).toString('base64');

    const clientData = client.toObject();
    delete clientData.password;

    res.status(200).json({
      success: true,
      data: {
        token,
        client: clientData,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const clientData = req.client.toObject();
    delete clientData.password;

    res.status(200).json({
      success: true,
      data: clientData,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { fullName, phone, address, landmark } = req.body;

    if (fullName) req.client.fullName = fullName;
    if (phone) req.client.phone = phone;
    if (address !== undefined) req.client.address = address;
    if (landmark !== undefined) req.client.landmark = landmark;

    await req.client.save();

    const clientData = req.client.toObject();
    delete clientData.password;

    res.status(200).json({
      success: true,
      data: clientData,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
