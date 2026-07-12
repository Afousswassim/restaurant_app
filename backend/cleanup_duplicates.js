require('dotenv').config();
const mongoose = require('mongoose');
const MenuItem = require('./models/MenuItem');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/food-delivery';

const cleanupDuplicates = async () => {
  await mongoose.connect(MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });

  console.log('Connected to MongoDB');

  const items = await MenuItem.find().lean();
  const keys = new Map();
  const duplicates = [];

  items.forEach((item) => {
    const normalizedKey = `${item.name.toLowerCase().trim()}|${item.category.toLowerCase().trim()}`;
    if (!keys.has(normalizedKey)) {
      keys.set(normalizedKey, item._id);
    } else {
      duplicates.push(item._id);
    }
  });

  if (duplicates.length === 0) {
    console.log('No duplicate menu items found.');
  } else {
    const result = await MenuItem.deleteMany({ _id: { $in: duplicates } });
    console.log(`Removed ${result.deletedCount} duplicate menu item(s).`);
  }

  await mongoose.disconnect();
  console.log('Disconnected from MongoDB');
};

cleanupDuplicates()
  .catch((error) => {
    console.error('Cleanup failed:', error);
    process.exit(1);
  });
