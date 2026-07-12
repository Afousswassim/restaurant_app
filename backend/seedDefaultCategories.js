const mongoose = require('mongoose');
const connectDB = require('./config/database');
const Category = require('./models/Category');

const defaults = [
  { name: 'Burger', description: 'Classic burgers', icon: 'lunch_dining', sortOrder: 1 },
  { name: 'Pizza', description: 'Fresh pizzas', icon: 'local_pizza', sortOrder: 2 },
  { name: 'Crepe', description: 'Sweet and savory crepes', icon: 'set_meal', sortOrder: 3 },
  { name: 'Dessert', description: 'Desserts and sweets', icon: 'icecream', sortOrder: 4 },
  { name: 'Drinks', description: 'Refreshing drinks', icon: 'local_cafe', sortOrder: 5 },
];

async function seedDefaultCategories() {
  try {
    await connectDB();
    for (const item of defaults) {
      const existing = await Category.findOne({
        name: { $regex: `^${item.name}$`, $options: 'i' },
      });
      if (!existing) {
        await Category.create({ ...item, status: 'Active' });
        console.log(`Created default category: ${item.name}`);
      } else {
        console.log(`Default category already exists: ${item.name}`);
      }
    }
    console.log('Default categories seed completed');
  } catch (error) {
    console.error('Default categories seed failed:', error.message);
  }
}

if (require.main === module) {
  seedDefaultCategories()
    .then(() => mongoose.disconnect())
    .catch((error) => {
      console.error('Error seeding default categories:', error.message);
      mongoose.disconnect();
    });
}

module.exports = { seedDefaultCategories };
