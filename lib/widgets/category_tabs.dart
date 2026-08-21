import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryTabs extends StatelessWidget {
  final List<CategoryModel> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  IconData _getCategoryIconData(String iconName) {
    switch (iconName.toLowerCase().trim()) {
      case 'local_pizza':
      case 'pizza':
        return Icons.local_pizza_rounded;
      case 'lunch_dining':
      case 'burger':
      case 'burgers':
        return Icons.lunch_dining_rounded;
      case 'local_cafe':
      case 'drinks':
      case 'drink':
      case 'beverage':
      case 'beverages':
        return Icons.local_cafe_rounded;
      case 'icecream':
      case 'dessert':
      case 'desserts':
      case 'sweet':
      case 'sweets':
        return Icons.icecream_rounded;
      case 'crepe':
      case 'bakery_dining':
      case 'bakery':
        return Icons.bakery_dining_rounded;
      case 'set_meal':
      case 'tacos':
      case 'meal':
      case 'meals':
        return Icons.set_meal_rounded;
      case 'ramen_dining':
      case 'noodle':
      case 'noodles':
        return Icons.ramen_dining_rounded;
      case 'dinner_dining':
        return Icons.dinner_dining_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'flatware':
        return Icons.flatware_rounded;
      case 'local_offer':
      case 'offer':
      case 'offers':
        return Icons.local_offer_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }

  Widget _buildCategoryAvatar(String rawIcon, bool isSelected) {
    if (rawIcon == '🔎' || rawIcon == '🍽️' || rawIcon.runes.length <= 2) {
      return Text(rawIcon, style: const TextStyle(fontSize: 14));
    }
    final iconData = _getCategoryIconData(rawIcon);
    return Icon(
      iconData,
      size: 18,
      color: isSelected ? Colors.white : Colors.deepOrange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final visibleCategories = <Map<String, String>>[
      {'name': 'All', 'icon': '🔎'},
      ...categories.map(
        (category) => {
          'name': category.name,
          'icon': category.icon.isNotEmpty ? category.icon : '🍽️',
        },
      ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: visibleCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = visibleCategories[index];
          final name = cat['name']!;
          final rawIcon = cat['icon']!;
          final isSelected = selectedCategory.toLowerCase() == name.toLowerCase();

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelectCategory(name),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.deepOrange
                      : (isDark ? const Color(0xFF282828) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.deepOrange
                        : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Colors.deepOrange.withOpacity(0.3)
                          : Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCategoryAvatar(rawIcon, isSelected),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF2C1810)),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
