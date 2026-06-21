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
    // Define menu items (prices in DH)
    const menuItemsData = [
      // Burgers
      {
        name: 'Burger Combo',
        description: '2 Burgers + Fries + Drink. The ultimate meal for burger lovers.',
        price: 199,
        hasOffer: true,
        oldPrice: 199,
        offerPrice: 129,
        offerExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        offerLabel: "35% OFF",
        imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900&auto=format&fit=crop&q=80',
        category: 'Burger',
        rating: 4.8,
        extras: [ { name: 'Extra sauce', price: 5 }, { name: 'Onion rings', price: 15 } ],
      },
      {
        name: 'Classic Burger',
        description: 'Juicy beef patty with fresh lettuce, tomato and house sauce.',
        price: 45,
        imageUrl: 'https://images.unsplash.com/photo-1550317138-10000687a72b?w=900&auto=format&fit=crop&q=80',
        category: 'Burger',
        extras: [ { name: 'Extra cheese', price: 15 }, { name: 'Bacon slice', price: 10 } ],
      },
      {
        name: 'Chicken Burger',
        description: 'Crispy chicken breast, pickles and melted cheese.',
        price: 55,
        imageUrl: 'https://images.unsplash.com/photo-1606756792343-4b6f7f1f6f9f?w=900&auto=format&fit=crop&q=80',
        category: 'Burger',
        extras: [ { name: 'Extra chicken', price: 20 }, { name: 'Spicy sauce', price: 5 } ],
      },
      {
        name: 'Double Cheese Burger',
        description: 'Two flame-grilled patties with double cheddar.',
        price: 70,
        imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=900&auto=format&fit=crop&q=80',
        category: 'Burger',
        extras: [ { name: 'Extra cheese', price: 15 } ],
      },
      {
        name: 'Crispy Burger',
        description: 'Golden fried chicken, crunchy slaw and spicy mayo.',
        price: 75,
        imageUrl: 'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=900&auto=format&fit=crop&q=80',
        category: 'Burger',
        rating: 4.6,
        extras: [ { name: 'Extra cheese', price: 15 } ],
      },
      {
        name: 'Veggie Burger',
        description: 'Plant-based patty with fresh greens and special sauce.',
        price: 48,
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=900&auto=format&fit=crop&q=80',
        category: 'Burger',
        rating: 4.5,
        extras: [ { name: 'Extra cheese', price: 15 } ],
      },

      // Pizza
      {
        name: 'Family Pizza Box',
        description: '2 delicious medium pizzas + drinks. Perfect for a family night.',
        price: 250,
        hasOffer: true,
        oldPrice: 250,
        offerPrice: 179,
        offerExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        offerLabel: "28% OFF",
        imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=900&auto=format&fit=crop&q=80',
        category: 'Pizza',
        rating: 4.9,
        extras: [ { name: 'Extra cheese crust', price: 20 }, { name: 'Garlic bread', price: 18 } ],
      },
      {
        name: 'Pizza Margarita',
        description: 'Neapolitan pizza with tomato, mozzarella and basil.',
        price: 50,
        imageUrl: 'https://images.unsplash.com/photo-1542281286-9e0a16bb7366?w=900&auto=format&fit=crop&q=80',
        category: 'Pizza',
        extras: [ { name: 'Extra cheese', price: 15 }, { name: 'Olives', price: 5 } ],
      },
      {
        name: 'Pizza Chicken',
        description: 'Grilled chicken, peppers and BBQ drizzle.',
        price: 65,
        imageUrl: 'https://images.unsplash.com/photo-1601924582975-f9d2ab7230c1?w=900&auto=format&fit=crop&q=80',
        category: 'Pizza',
        extras: [ { name: 'Extra chicken', price: 20 } ],
      },
      {
        name: 'Pizza 4 Fromages',
        description: 'Mozzarella, gorgonzola, parmesan and goat cheese.',
        price: 75,
        imageUrl: 'https://images.unsplash.com/photo-1573821663912-569905455b1c?w=900&auto=format&fit=crop&q=80',
        category: 'Pizza',
        extras: [ { name: 'Honey drizzle', price: 8 } ],
      },
      {
        name: 'Pizza Pepperoni',
        description: 'Classic pepperoni with melted cheese.',
        price: 80,
        imageUrl: 'https://images.unsplash.com/photo-1548365328-7f9b0b6d1d5d?w=900&auto=format&fit=crop&q=80',
        category: 'Pizza',
        rating: 4.7,
        extras: [ { name: 'Extra pepperoni', price: 15 } ],
      },
      {
        name: 'Pizza Funghi',
        description: 'Mushrooms, garlic, and herb oil on a thin crust.',
        price: 70,
        imageUrl: 'https://images.unsplash.com/photo-1601924582975-f9d2ab7230c1?w=900&auto=format&fit=crop&q=80',
        category: 'Pizza',
        rating: 4.6,
        extras: [ { name: 'Extra mushrooms', price: 10 } ],
      },

      // Crepes
      {
        name: 'Sweet Crepe Offer',
        description: 'Buy 2 Sweet Crepes and get extra Nutella and banana toppings.',
        price: 135,
        hasOffer: true,
        oldPrice: 135,
        offerPrice: 90,
        offerExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        offerLabel: "33% OFF",
        imageUrl: 'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=900&auto=format&fit=crop&q=80',
        category: 'Crepe',
        rating: 4.7,
        extras: [ { name: 'Vanilla ice cream', price: 12 }, { name: 'Whipped cream', price: 6 } ],
      },
      {
        name: 'Nutella Crepe',
        description: 'Warm crepe loaded with premium Nutella.',
        price: 35,
        imageUrl: 'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=900&auto=format&fit=crop&q=80',
        category: 'Crepe',
        extras: [ { name: 'Banana slices', price: 8 }, { name: 'Whipped cream', price: 6 } ],
      },
      {
        name: 'Chicken Crepe',
        description: 'Savory crepe with grilled chicken and cheese.',
        price: 45,
        imageUrl: 'https://images.unsplash.com/photo-1621303837876-2970de1d7fce?w=900&auto=format&fit=crop&q=80',
        category: 'Crepe',
        extras: [ { name: 'Extra cheese', price: 15 } ],
      },
      {
        name: 'Mixed Crepe',
        description: 'Nutella crepe with strawberries and banana.',
        price: 55,
        imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=900&auto=format&fit=crop&q=80',
        category: 'Crepe',
        extras: [ { name: 'Vanilla ice cream', price: 12 } ],
      },
      {
        name: 'Cheese Crepe',
        description: 'Creamy cheese-filled crepe with herbs.',
        price: 40,
        imageUrl: 'https://images.unsplash.com/photo-1618307889114-d5980a2c5d33?w=900&auto=format&fit=crop&q=80',
        category: 'Crepe',
        rating: 4.5,
        extras: [ { name: 'Extra cheese', price: 12 } ],
      },
      {
        name: 'Banana Crepe',
        description: 'Sweet crepe with caramelized bananas and cinnamon.',
        price: 38,
        imageUrl: 'https://images.unsplash.com/photo-1505250469679-203ad9ced0cb?w=900&auto=format&fit=crop&q=80',
        category: 'Crepe',
        rating: 4.4,
        extras: [ { name: 'Vanilla ice cream', price: 12 } ],
      },

      // Desserts
      {
        name: 'Chocolate Cake',
        description: 'Rich and moist chocolate layer cake.',
        price: 40,
        imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=900&auto=format&fit=crop&q=80',
        category: 'Dessert',
        extras: [ { name: 'Ice cream scoop', price: 12 } ],
      },
      {
        name: 'Waffle Nutella',
        description: 'Belgian waffle drizzled with Nutella.',
        price: 45,
        imageUrl: 'https://images.unsplash.com/photo-1562376502-6f769499c886?w=900&auto=format&fit=crop&q=80',
        category: 'Dessert',
        extras: [ { name: 'Banana', price: 8 } ],
      },
      {
        name: 'Tiramisu',
        description: 'Creamy layered coffee dessert with cocoa.',
        price: 50,
        imageUrl: 'https://images.unsplash.com/photo-1605475126634-4d63d8f68693?w=900&auto=format&fit=crop&q=80',
        category: 'Dessert',
        extras: [ { name: 'Mascarpone cream', price: 10 } ],
      },
      {
        name: 'Pancake',
        description: 'Fluffy pancakes with maple syrup and berries.',
        price: 45,
        imageUrl: 'https://images.unsplash.com/photo-1563805042-7684a25f5853?w=900&auto=format&fit=crop&q=80',
        category: 'Dessert',
        rating: 4.6,
        extras: [ { name: 'Whipped cream', price: 6 } ],
      },
      {
        name: 'Cheesecake',
        description: 'Classic creamy cheesecake with a buttery crust.',
        price: 55,
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=900&auto=format&fit=crop&q=80',
        category: 'Dessert',
        rating: 4.7,
        extras: [ { name: 'Berry compote', price: 10 } ],
      },

      // Drinks
      {
        name: 'Coca Cola',
        description: 'Classic chilled Coca-Cola.',
        price: 10,
        imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=900&auto=format&fit=crop&q=80',
        category: 'Drinks',
        extras: [ { name: 'Ice cubes', price: 2 } ],
      },
      {
        name: 'Orange Juice',
        description: '100% freshly squeezed orange juice.',
        price: 18,
        imageUrl: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=900&auto=format&fit=crop&q=80',
        category: 'Drinks',
        extras: [ { name: 'Ice cubes', price: 2 } ],
      },
      {
        name: 'Water',
        description: 'Refreshing bottled water.',
        price: 7,
        imageUrl: 'https://images.unsplash.com/photo-1510626176961-4b6550f32c68?w=900&auto=format&fit=crop&q=80',
        category: 'Drinks',
        extras: [ { name: 'Lemon slice', price: 2 } ],
      },
      {
        name: 'Milkshake',
        description: 'Creamy milkshake made with premium ice cream.',
        price: 30,
        imageUrl: 'https://images.unsplash.com/photo-1542444459-db0c80d1d3f0?w=900&auto=format&fit=crop&q=80',
        category: 'Drinks',
        rating: 4.5,
        extras: [ { name: 'Whipped cream', price: 6 } ],
      },
      {
        name: 'Iced Coffee',
        description: 'Chilled coffee over ice with a hint of vanilla.',
        price: 22,
        imageUrl: 'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=900&auto=format&fit=crop&q=80',
        category: 'Drinks',
        rating: 4.4,
        extras: [ { name: 'Extra syrup', price: 3 } ],
      },
    ];

    const itemsToCreate = [];
    branches.forEach((branch) => {
      menuItemsData.forEach((item) => {
        itemsToCreate.push({
          ...item,
          branchId: branch._id,
        });
      });
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
