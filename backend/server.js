require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const connectDB = require('./config/database');

const branchRoutes = require('./routes/branches');
const menuRoutes = require('./routes/menu');
const categoriesRoutes = require('./routes/categories');
const cartRoutes = require('./routes/cart');
const orderRoutes = require('./routes/orders');
const notificationRoutes = require('./routes/notifications');
const adminRoutes = require('./routes/adminRoutes');
const offerRoutes = require('./routes/offerRoutes');
const clientRoutes = require('./routes/clients');
const couponRoutes = require('./routes/coupons');
const loyaltyRoutes = require('./routes/loyalty');
const aiRoutes = require('./routes/aiRoutes');
const { seedDefaultCategories } = require('./seedDefaultCategories');
const errorHandler = require('./middleware/errorHandler');

const app = express();

connectDB();

app.use(cors());

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

app.use('/branches', branchRoutes);
app.use('/menu', menuRoutes);
app.use('/categories', categoriesRoutes);
app.use('/cart', cartRoutes);
app.use('/orders', orderRoutes);
app.use('/notifications', notificationRoutes);
app.use('/admin', adminRoutes);
app.use('/admin/offers', offerRoutes.adminRouter);
app.use('/offers', offerRoutes.publicRouter);
app.use('/clients', clientRoutes);
app.use('/coupons', couponRoutes);
app.use('/loyalty', loyaltyRoutes);
app.use('/ai', aiRoutes);

app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is running',
  });
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

app.use(errorHandler);

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();
  await seedDefaultCategories();

  const server = app.listen(PORT, () => {
    console.log(`🚀 Food Delivery Backend running on http://localhost:${PORT}`);
  });

  server.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
      console.error(`Port ${PORT} is already in use. Use a different PORT or stop the process currently listening on it.`);
    } else {
      console.error('Server error:', error);
    }
    process.exit(1);
  });
};

startServer().catch((error) => {
  console.error('Failed to start server:', error.message);
  process.exit(1);
});

module.exports = app;
