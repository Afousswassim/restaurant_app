const mongoose = require('mongoose');
const dns = require('dns');

let connectionPromise = null;

const connectDB = async () => {
  // 1 = connected, 2 = connecting
  if (mongoose.connection.readyState === 1) {
    return mongoose.connection;
  }

  if (connectionPromise) {
    return connectionPromise;
  }

  // Fallback DNS servers to prevent local Windows DNS SRV query refusal (ECONNREFUSED / ETIMEOUT)
  try {
    dns.setServers(['8.8.8.8', '1.1.1.1']);
  } catch (e) {
    // Ignore if custom DNS servers cannot be set
  }

  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/food-delivery';

  connectionPromise = mongoose
    .connect(mongoUri)
    .then((conn) => {
      console.log('MongoDB connected successfully');
      return conn;
    })
    .catch((error) => {
      connectionPromise = null;
      console.error('MongoDB connection error:', error.message);
      process.exit(1);
    });

  return connectionPromise;
};

module.exports = connectDB;
