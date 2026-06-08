require('dotenv').config();
const mongoose = require('mongoose');
const Restaurant = require('./models/Restaurant');
const MenuItem = require('./models/MenuItem');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/food-delivery';

const seedDatabase = async () => {
  try {
    await mongoose.connect(MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log('Connected to MongoDB');

    // Clear existing data
    await Restaurant.deleteMany({});
    await MenuItem.deleteMany({});

    // Create restaurants
    const restaurants = await Restaurant.create([
      {
        name: 'Burger House',
        description: 'Delicious and juicy craft burgers made with fresh ingredients',
        imageUrl: 'https://source.unsplash.com/800x600/?burger',
        rating: 4.7,
        deliveryTime: 25,
        deliveryFee: 15,
        minOrder: 40,
        cuisine: 'American',
        category: 'Burger',
        averagePrice: 65,
        isOpen: true,
      },
      {
        name: 'Pizza Napoli',
        description: 'Authentic stone-baked Italian pizzas',
        imageUrl: 'https://source.unsplash.com/800x600/?pizza',
        rating: 4.6,
        deliveryTime: 30,
        deliveryFee: 15,
        minOrder: 50,
        cuisine: 'Italian',
        category: 'Pizza',
        averagePrice: 80,
        isOpen: true,
      },
      {
        name: 'Fresh Salad Bar',
        description: 'Healthy and organic salad bowls',
        imageUrl: 'https://source.unsplash.com/800x600/?salad',
        rating: 4.4,
        deliveryTime: 20,
        deliveryFee: 10,
        minOrder: 30,
        cuisine: 'Healthy',
        category: 'Salad',
        averagePrice: 55,
        isOpen: true,
      },
      {
        name: 'Sweet Dessert',
        description: 'Heavenly sweets, cakes, and treats',
        imageUrl: 'https://source.unsplash.com/800x600/?dessert',
        rating: 4.8,
        deliveryTime: 25,
        deliveryFee: 12,
        minOrder: 30,
        cuisine: 'French',
        category: 'Dessert',
        averagePrice: 45,
        isOpen: true,
      },
    ]);

    console.log('✅ Restaurants created');

    // Create menu items for each restaurant
    const menuData = [
      // Burger House
      {
        restaurantId: restaurants[0]._id,
        items: [
          { name: 'Cheeseburger Classic', description: 'Juicy beef patty with cheddar, lettuce, tomato and signature sauce', price: 55, category: 'Burger', imageUrl: 'https://source.unsplash.com/800x600/?burger' },
          { name: 'Double Cheese Bacon', description: 'Double beef patty, crispy bacon, double cheddar cheese', price: 90, category: 'Burger', imageUrl: 'https://source.unsplash.com/800x600/?cheeseburger' },
          { name: 'Crispy Fries', description: 'Crispy golden french fries served with dip', price: 35, category: 'Sides', imageUrl: 'https://source.unsplash.com/800x600/?fries' },
          { name: 'Onion Rings', description: 'Golden battered onion rings', price: 35, category: 'Sides', imageUrl: 'https://source.unsplash.com/800x600/?onion-rings' },
          { name: 'Soft Drink', description: 'Refreshing Coca-Cola or Fanta', price: 35, category: 'Drinks', imageUrl: 'https://source.unsplash.com/800x600/?soda' },
        ],
      },
      // Pizza Napoli
      {
        restaurantId: restaurants[1]._id,
        items: [
          { name: 'Margherita Napoli', description: 'San Marzano tomatoes, fresh mozzarella, fresh basil and olive oil', price: 70, category: 'Pizza', imageUrl: 'https://source.unsplash.com/800x600/?margherita' },
          { name: 'Pizza Regina', description: 'Tomato sauce, mozzarella, mushrooms and premium turkey ham', price: 90, category: 'Pizza', imageUrl: 'https://source.unsplash.com/800x600/?pizza-slice' },
          { name: 'Four Cheese Pizza', description: 'Mozzarella, gorgonzola, parmesan and goat cheese', price: 120, category: 'Pizza', imageUrl: 'https://source.unsplash.com/800x600/?cheese-pizza' },
          { name: 'Garlic Bread', description: 'Toasted baguette with garlic butter and fresh parsley', price: 35, category: 'Sides', imageUrl: 'https://source.unsplash.com/800x600/?garlic-bread' },
          { name: 'Italian Tiramisu', description: 'Classic tiramisu with coffee and mascarpone', price: 45, category: 'Dessert', imageUrl: 'https://source.unsplash.com/800x600/?tiramisu' },
        ],
      },
      // Fresh Salad Bar
      {
        restaurantId: restaurants[2]._id,
        items: [
          { name: 'Greek Salad', description: 'Cucumbers, tomatoes, red onion, olives and feta cheese with dressing', price: 45, category: 'Salad', imageUrl: 'https://source.unsplash.com/800x600/?greek-salad' },
          { name: 'Chicken Caesar Salad', description: 'Grilled chicken breast, romaine lettuce, parmesan cheese and croutons', price: 70, category: 'Salad', imageUrl: 'https://source.unsplash.com/800x600/?caesar-salad' },
          { name: 'Quinoa Avocado Bowl', description: 'Quinoa, fresh avocado, cherry tomatoes and spinach', price: 90, category: 'Salad', imageUrl: 'https://source.unsplash.com/800x600/?quinoa-salad' },
          { name: 'Detox Green Juice', description: 'Freshly squeezed cucumber, apple, spinach and ginger juice', price: 35, category: 'Drinks', imageUrl: 'https://source.unsplash.com/800x600/?green-juice' },
        ],
      },
      // Sweet Dessert
      {
        restaurantId: restaurants[3]._id,
        items: [
          { name: 'Chocolate Lava Cake', description: 'Warm chocolate cake with a rich molten chocolate center', price: 45, category: 'Dessert', imageUrl: 'https://source.unsplash.com/800x600/?lava-cake' },
          { name: 'Strawberry Cheesecake', description: 'Creamy New York style cheesecake with strawberry compote', price: 55, category: 'Dessert', imageUrl: 'https://source.unsplash.com/800x600/?cheesecake' },
          { name: 'Macaron Box', description: 'Assortment of 6 delicious french macarons', price: 90, category: 'Dessert', imageUrl: 'https://source.unsplash.com/800x600/?macarons' },
          { name: 'Hot Chocolate Fudge', description: 'Decadent chocolate brownie topped with hot fudge', price: 45, category: 'Dessert', imageUrl: 'https://source.unsplash.com/800x600/?brownie' },
        ],
      },
    ];

    for (const restaurant of menuData) {
      await MenuItem.create(
        restaurant.items.map((item) => ({
          ...item,
          restaurantId: restaurant.restaurantId,
        }))
      );
    }

    console.log('✅ Menu items created');

    await mongoose.connection.close();
    console.log('✅ Database seeding completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error.message);
    process.exit(1);
  }
};

seedDatabase();
