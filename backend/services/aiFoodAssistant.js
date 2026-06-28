const MenuItem = require('../models/MenuItem');
const Order = require('../models/Order');

const goalTagMap = {
  healthy: 'healthy',
  'high protein': 'high-protein',
  'low calories': 'low-calorie',
  'family meal': 'family',
  'budget friendly': 'budget',
};

const complementaryCategories = {
  Burger: ['Burger', 'Drinks', 'Dessert'],
  Pizza: ['Pizza', 'Drinks', 'Dessert'],
  Crepe: ['Crepe', 'Drinks', 'Dessert'],
  Dessert: ['Dessert', 'Drinks'],
  Drinks: ['Burger', 'Pizza', 'Crepe', 'Drinks'],
};

const normalize = (value) => String(value || '').trim().toLowerCase();

const effectivePrice = (item) => {
  const hasActiveOffer = item.hasOffer && item.offerPrice && (!item.offerExpiresAt || new Date(item.offerExpiresAt) > new Date());
  return hasActiveOffer ? item.offerPrice : item.price;
};

const toResponseItem = (item, reason) => ({
  _id: item._id,
  branchId: item.branchId,
  name: item.name,
  description: item.description,
  price: effectivePrice(item),
  imageUrl: item.imageUrl,
  category: item.category,
  extras: item.extras || [],
  isAvailable: item.isAvailable,
  rating: item.rating,
  calories: item.calories || 0,
  protein: item.protein || 0,
  carbs: item.carbs || 0,
  fat: item.fat || 0,
  tags: item.tags || [],
  reason,
});

const buildPlan = (title, items, reason) => ({
  title,
  items,
  total: items.reduce((sum, item) => sum + Number(item.price || 0), 0),
  reason,
});

const getAvailableItems = async (branchId) => {
  const filter = { isAvailable: true };
  if (branchId) {
    filter.$or = [
      { branchId: { $exists: false } },
      { branchId: null },
      { branchId },
    ];
  }

  return MenuItem.find(filter).sort({ rating: -1, price: 1 });
};

const getMostOrderedCategory = async (clientId) => {
  if (!clientId) return null;

  const orders = await Order.find({ clientId }).sort({ createdAt: -1 }).limit(20).populate('items.menuItemId');
  const counts = {};

  orders.forEach((order) => {
    order.items.forEach((orderItem) => {
      const category = orderItem.menuItemId?.category;
      if (category) {
        counts[category] = (counts[category] || 0) + (orderItem.quantity || 1);
      }
    });
  });

  return Object.entries(counts).sort((a, b) => b[1] - a[1])[0]?.[0] || null;
};

const recommendFromHistory = async ({ clientId, branchId }) => {
  const items = await getAvailableItems(branchId);
  const favoriteCategory = await getMostOrderedCategory(clientId);
  const categories = favoriteCategory ? complementaryCategories[favoriteCategory] || [favoriteCategory] : ['Burger', 'Pizza', 'Crepe', 'Drinks'];

  const selected = [];
  categories.forEach((category) => {
    const match = items.find((item) => item.category === category && !selected.some((selectedItem) => selectedItem.id === item.id));
    if (match && selected.length < 4) {
      selected.push(match);
    }
  });

  if (selected.length === 0) {
    selected.push(...items.slice(0, 3));
  }

  const label = favoriteCategory || 'popular menu';
  return buildPlan(
    'AI Recommended Meal Plan',
    selected.map((item) => toResponseItem(item, `Recommended because it matches your ${label} taste.`)),
    favoriteCategory
      ? `Based on your previous orders, ${favoriteCategory} is your most ordered category.`
      : 'No order history found yet, so these popular items are a smart first pick.'
  );
};

const recommendForNutrition = async ({ goal, branchId }) => {
  const tag = goalTagMap[normalize(goal)] || 'healthy';
  const items = await getAvailableItems(branchId);
  let selected = items.filter((item) => (item.tags || []).includes(tag)).slice(0, 4);

  if (selected.length === 0) {
    selected = items.slice(0, 3);
  }

  return buildPlan(
    `${goal || 'Healthy'} AI Suggestions`,
    selected.map((item) => toResponseItem(item, `Matches the ${goal || 'Healthy'} nutrition goal.`)),
    `These products were selected using the "${tag}" nutrition tag.`
  );
};

const planMeal = async ({ budget, people, preference, branchId }) => {
  const maxBudget = Math.max(Number(budget) || 0, 0);
  const peopleCount = Math.max(Number(people) || 1, 1);
  const preferredCategory = normalize(preference);
  const items = await getAvailableItems(branchId);
  const candidates = preferredCategory && preferredCategory !== 'any'
    ? items.filter((item) => normalize(item.category) === preferredCategory)
    : items;

  const selected = [];
  let total = 0;
  const addIfPossible = (item) => {
    if (!item) return false;
    if (selected.some((selectedItem) => selectedItem.id === item.id)) return false;
    const price = effectivePrice(item);
    if (total + price > maxBudget) return false;
    selected.push(item);
    total += price;
    return true;
  };

  const mains = candidates.filter((item) => !['Drinks', 'Dessert'].includes(item.category)).sort((a, b) => effectivePrice(a) - effectivePrice(b));
  const drinks = items.filter((item) => item.category === 'Drinks').sort((a, b) => effectivePrice(a) - effectivePrice(b));
  const desserts = items.filter((item) => item.category === 'Dessert').sort((a, b) => effectivePrice(a) - effectivePrice(b));

  for (let index = 0; index < peopleCount; index += 1) {
    addIfPossible(mains[index % Math.max(mains.length, 1)]);
  }

  if (selected.length === 0) {
    candidates.sort((a, b) => effectivePrice(a) - effectivePrice(b)).some((item) => addIfPossible(item));
  }

  addIfPossible(drinks[0]);
  addIfPossible(desserts[0]);

  const extras = items
    .filter((item) => !selected.some((selectedItem) => selectedItem.id === item.id))
    .sort((a, b) => effectivePrice(a) - effectivePrice(b));

  for (const item of extras) {
    if (selected.length >= peopleCount + 3) break;
    addIfPossible(item);
  }

  return buildPlan(
    'AI Recommended Meal Plan',
    selected.map((item) => toResponseItem(item, 'Fits your budget, group size, and meal preference.')),
    `This plan respects your ${maxBudget} DH budget and matches ${preference || 'Any'} preference for ${peopleCount} people.`
  );
};

const generateFoodAssistantPlan = async (payload) => {
  const mode = normalize(payload.mode);

  if (mode === 'nutrition') {
    return recommendForNutrition(payload);
  }

  if (mode === 'meal_planner') {
    return planMeal(payload);
  }

  return recommendFromHistory(payload);
};

module.exports = {
  generateFoodAssistantPlan,
};
