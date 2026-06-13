require('dotenv').config();
const mongoose = require('mongoose');
const Branch = require('./models/Branch');
const MenuItem = require('./models/MenuItem');
const CartItem = require('./models/CartItem');
const Order = require('./models/Order');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/food-delivery';

const seedDatabase = async () => {
  try {
    await mongoose.connect(MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log('Connected to MongoDB');

    // Clear old data for test
    await Branch.deleteMany({});
    await MenuItem.deleteMany({});
    await CartItem.deleteMany({});
    await Order.deleteMany({});

    console.log('✅ Old branches, menu_items, cart_items, orders cleared');

    // Insert 3 Casablanca branches with slugs
    const branches = await Branch.create([
      {
        name: 'Maarif Branch',
        slug: 'maarif',
        address: 'Maarif, Casablanca',
        deliveryFee: 15,
        deliveryTime: '20-30 min',
      },
      {
        name: 'Ain Sebaa Branch',
        slug: 'ain-sebaa',
        address: 'Ain Sebaa, Casablanca',
        deliveryFee: 20,
        deliveryTime: '25-35 min',
      },
      {
        name: 'Sidi Maarouf Branch',
        slug: 'sidi-maarouf',
        address: 'Sidi Maarouf, Casablanca',
        deliveryFee: 25,
        deliveryTime: '30-40 min',
      },
    ]);

    console.log('✅ 3 Branches created successfully');

    // Define menu items
    const menuItemsData = [
      // Burger
      {
        name: 'Classic Burger',
        description: 'Juicy beef patty with fresh lettuce, tomato, and house special sauce.',
        price: 45,
        imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop&q=80',
        category: 'Burger',
        extras: [
          { name: 'Extra cheese', price: 15 },
          { name: 'Extra beef patty', price: 25 },
          { name: 'Bacon slice', price: 10 },
        ],
      },
      {
        name: 'Chicken Burger',
        description: 'Crispy chicken breast, creamy mayo, pickles, and melted cheese.',
        price: 55,
        imageUrl: 'https://images.unsplash.com/photo-1625813506062-0aeb1d7a094b?w=600&auto=format&fit=crop&q=80',
        category: 'Burger',
        extras: [
          { name: 'Extra cheese', price: 15 },
          { name: 'Extra chicken patty', price: 20 },
          { name: 'Spicy sauce', price: 5 },
        ],
      },
      {
        name: 'Double Cheese Burger',
        description: 'Two flame-grilled beef patties with double cheddar cheese and caramelized onions.',
        price: 70,
        imageUrl: 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=600&auto=format&fit=crop&q=80',
        category: 'Burger',
        extras: [
          { name: 'Extra cheese', price: 15 },
          { name: 'Bacon slice', price: 10 },
        ],
      },
      // Pizza
      {
        name: 'Pizza Margarita',
        description: 'Authentic Neapolitan pizza with tomato sauce, fresh mozzarella, and fresh basil.',
        price: 50,
        imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&auto=format&fit=crop&q=80',
        category: 'Pizza',
        extras: [
          { name: 'Extra cheese', price: 15 },
          { name: 'Mushrooms', price: 10 },
          { name: 'Olives', price: 5 },
        ],
      },
      {
        name: 'Pizza Chicken',
        description: 'Tender grilled chicken, bell peppers, onions, and sweet BBQ drizzle.',
        price: 65,
        imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&auto=format&fit=crop&q=80',
        category: 'Pizza',
        extras: [
          { name: 'Extra cheese', price: 15 },
          { name: 'Extra chicken', price: 20 },
          { name: 'Jalapenos', price: 8 },
        ],
      },
      {
        name: 'Pizza 4 Fromages',
        description: 'A rich combination of mozzarella, gorgonzola, parmesan, and goat cheese.',
        price: 75,
        imageUrl: 'https://images.unsplash.com/photo-1573821663912-569905455b1c?w=600&auto=format&fit=crop&q=80',
        category: 'Pizza',
        extras: [
          { name: 'Honey drizzle', price: 8 },
          { name: 'Extra cheese', price: 15 },
        ],
      },
      // Crepe
      {
        name: 'Nutella Crepe',
        description: 'Warm crepe loaded with premium Nutella chocolate spread.',
        price: 35,
        imageUrl: 'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=600&auto=format&fit=crop&q=80',
        category: 'Crepe',
        extras: [
          { name: 'Add banana slices', price: 8 },
          { name: 'Add strawberry slices', price: 10 },
          { name: 'Whipped cream', price: 6 },
        ],
      },
      {
        name: 'Chicken Crepe',
        description: 'Savory crepe stuffed with grilled chicken, cheese, and creamy bechamel sauce.',
        price: 45,
        imageUrl: 'https://images.unsplash.com/photo-1621303837876-2970de1d7fce?w=600&auto=format&fit=crop&q=80',
        category: 'Crepe',
        extras: [
          { name: 'Extra cheese', price: 15 },
          { name: 'Mushrooms', price: 10 },
        ],
      },
      {
        name: 'Mixed Crepe',
        description: 'The ultimate crepe combining sweet Nutella, fresh strawberries, and banana.',
        price: 55,
        imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=600&auto=format&fit=crop&q=80',
        category: 'Crepe',
        extras: [
          { name: 'Vanilla ice cream', price: 12 },
          { name: 'Crushed nuts', price: 8 },
        ],
      },
      // Dessert
      {
        name: 'Chocolate Cake',
        description: 'Rich and moist chocolate layer cake topped with chocolate fudge.',
        price: 40,
        imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&auto=format&fit=crop&q=80',
        category: 'Dessert',
        extras: [
          { name: 'Vanilla ice cream scoop', price: 12 },
          { name: 'Whipped cream', price: 6 },
        ],
      },
      {
        name: 'Waffle Nutella',
        description: 'Freshly baked warm Belgian waffle, drizzled with hot Nutella.',
        price: 45,
        imageUrl: 'https://images.unsplash.com/photo-1562376502-6f769499c886?w=600&auto=format&fit=crop&q=80',
        category: 'Dessert',
        extras: [
          { name: 'Add banana', price: 8 },
          { name: 'Add strawberry', price: 10 },
          { name: 'Whipped cream', price: 6 },
        ],
      },
      // Drinks
      {
        name: 'Coca Cola',
        description: 'Classic chilled Coca-Cola.',
        price: 10,
        imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=600&auto=format&fit=crop&q=80',
        category: 'Drinks',
        extras: [
          { name: 'Ice cubes', price: 2 },
          { name: 'Lemon slice', price: 2 },
        ],
      },
      {
        name: 'Orange Juice',
        description: '100% freshly squeezed natural orange juice.',
        price: 18,
        imageUrl: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=600&auto=format&fit=crop&q=80',
        category: 'Drinks',
        extras: [
          { name: 'Ice cubes', price: 2 },
        ],
      },
    ];

    // Seed menu items and assign to branches
    const itemsToCreate = [];
    // simple assignment: first 6 items -> maarif, next 6 -> ain-sebaa, rest -> sidi-maarouf
    const maarifId = branches[0]._id;
    const ainSebaaId = branches[1]._id;
    const sidiMaaroufId = branches[2]._id;

    menuItemsData.forEach((it, idx) => {
      const copy = Object.assign({}, it);
      if (idx < 6) copy.branchId = maarifId;
      else if (idx < 12) copy.branchId = ainSebaaId;
      else copy.branchId = sidiMaaroufId;
      itemsToCreate.push(copy);
    });

    await MenuItem.create(itemsToCreate);

    console.log('✅ Menu items seeded successfully');

    await mongoose.connection.close();
    console.log('✅ Database seeding completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error.message);
    process.exit(1);
  }
};

seedDatabase();
