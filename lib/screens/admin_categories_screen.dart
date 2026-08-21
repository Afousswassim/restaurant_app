import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/menu_provider.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Active, Inactive, Empty Categories
  String _selectedSort = 'Newest'; // Newest, Alphabetical, Most Products, Oldest

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories(admin: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryModel> get _filteredCategories {
    final categories = context.watch<CategoryProvider>().categories;
    List<CategoryModel> filtered = categories.where((cat) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!cat.name.toLowerCase().contains(query) &&
            !cat.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      if (_selectedFilter == 'Active' && cat.status != 'Active') return false;
      if (_selectedFilter == 'Inactive' && cat.status != 'Inactive') return false;
      if (_selectedFilter == 'Empty Categories' && cat.productCount > 0) return false;

      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'Alphabetical':
          return a.name.compareTo(b.name);
        case 'Most Products':
          return b.productCount.compareTo(a.productCount);
        case 'Oldest':
          return a.createdAt.compareTo(b.createdAt);
        case 'Newest':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return filtered;
  }

  Future<void> _showCategoryDialog([CategoryModel? category]) async {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    final iconController = TextEditingController(text: category?.icon ?? 'fastfood');
    final imageController = TextEditingController(text: category?.image ?? '');
    final sortOrderController = TextEditingController(text: category?.sortOrder.toString() ?? '0');
    String status = category?.status ?? 'Active';

    await showDialog(
      context: context,
      builder: (context) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit Category' : 'Add New Category',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Category Name',
                          prefixIcon: const Icon(Icons.label_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Short Description',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: iconController,
                        decoration: InputDecoration(
                          labelText: 'Icon Name (e.g. burger, pizza, drinks, crepe)',
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: imageController,
                        decoration: InputDecoration(
                          labelText: 'Banner Image URL (Optional)',
                          prefixIcon: const Icon(Icons.image_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: sortOrderController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Display Order',
                          prefixIcon: const Icon(Icons.sort_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          prefixIcon: const Icon(Icons.toggle_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: ['Active', 'Inactive']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => status = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);

                    try {
                      final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;
                      if (isEditing) {
                        await context.read<CategoryProvider>().updateCategory(category.id, {
                          'name': nameController.text.trim(),
                          'description': descController.text.trim(),
                          'icon': iconController.text.trim(),
                          'image': imageController.text.trim(),
                          'status': status,
                          'sortOrder': sortOrder,
                        });
                      } else {
                        await context.read<CategoryProvider>().createCategory(
                          CategoryModel(
                            id: '',
                            name: nameController.text.trim(),
                            description: descController.text.trim(),
                            icon: iconController.text.trim(),
                            image: imageController.text.trim(),
                            status: status,
                            sortOrder: sortOrder,
                            createdAt: DateTime.now(),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving category: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isEditing ? 'Save Changes' : 'Create Category'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final destinationCategories = context
        .read<CategoryProvider>()
        .categories
        .where((item) => item.id != category.id)
        .toList();
    String? selectedDestinationId;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.delete_forever_rounded, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Delete Category', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.productCount > 0
                          ? 'This category has ${category.productCount} product(s). Choose a target category to move them into before deleting.'
                          : 'Are you sure you want to delete "${category.name}"?',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (category.productCount > 0) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedDestinationId,
                        decoration: InputDecoration(
                          labelText: 'Move products to',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: destinationCategories
                            .where((item) => item.status == 'Active')
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedDestinationId = value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm == true) {
      try {
        await context.read<CategoryProvider>().deleteCategory(
          category.id,
          targetCategoryId: selectedDestinationId,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete category: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleStatus(CategoryModel category) async {
    final newStatus = category.status == 'Active' ? 'Inactive' : 'Active';
    try {
      await context.read<CategoryProvider>().updateStatus(category.id, newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  void _showViewProductsDialog(CategoryModel category) {
    final products = context
        .read<MenuProvider>()
        .rawMenuItems
        .where((p) => p.category.toLowerCase() == category.name.toLowerCase())
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getCategoryIconData(category.icon), color: primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${category.name} Products',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    '${products.length} products available',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          height: 360,
          child: products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No products found in ${category.name}.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final p = products[i];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: p.imageUrl.isNotEmpty
                                  ? Image.network(
                                      p.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: primaryColor.withValues(alpha: 0.1),
                                        child: Icon(Icons.fastfood, color: primaryColor, size: 24),
                                      ),
                                    )
                                  : Container(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      child: Icon(Icons.fastfood, color: primaryColor, size: 24),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.price.toStringAsFixed(0)} DH',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (p.isAvailable ? Colors.green : Colors.red).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p.isAvailable ? 'In Stock' : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: p.isAvailable ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'local_pizza':
      case 'pizza':
        return Icons.local_pizza_rounded;
      case 'lunch_dining':
      case 'burger':
        return Icons.lunch_dining_rounded;
      case 'local_cafe':
      case 'drinks':
      case 'drink':
        return Icons.local_cafe_rounded;
      case 'icecream':
      case 'dessert':
      case 'desserts':
        return Icons.icecream_rounded;
      case 'crepe':
      case 'bakery_dining':
        return Icons.bakery_dining_rounded;
      case 'set_meal':
      case 'tacos':
        return Icons.set_meal_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }

  Widget _buildIconFallback(String iconName, Color primaryColor) {
    return Container(
      color: primaryColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          _getCategoryIconData(iconName),
          size: 36,
          color: primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final provider = context.watch<CategoryProvider>();
    final categories = provider.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Restaurant Hero Banner (Matching Product Page Style)
        Container(
          width: double.infinity,
          height: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.9),
                primaryColor.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.category_rounded,
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.category_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Menu Categories',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.restaurant_outlined, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Wassim Food • Category Management',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.grid_view_rounded, color: Color(0xFFFFC107), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${categories.length} Categories Total',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${categories.where((c) => c.status == "Active").length} Active',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Search & Add Category Action Row
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search menu categories...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Status Filter Pills & Sort Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              ...['All', 'Active', 'Inactive', 'Empty Categories'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                    selectedColor: primaryColor.withValues(alpha: 0.15),
                    checkmarkColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12,
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? primaryColor
                            : (isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
                        width: 1,
                      ),
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E1E26) : Colors.white,
                  ),
                );
              }),
              const SizedBox(width: 8),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    icon: const Icon(Icons.sort_rounded, size: 16),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                    ),
                    items: ['Newest', 'Alphabetical', 'Most Products', 'Oldest']
                        .map((s) => DropdownMenuItem(value: s, child: Text('Sort: $s')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSort = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 4. Categories Grid / List
        if (provider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_filteredCategories.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error != null
                        ? 'Failed to load categories: ${provider.error}'
                        : 'No categories found matching criteria.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.read<CategoryProvider>().loadCategories(admin: true),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              if (width < 650) {
                // Mobile single column list
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _buildModernCategoryCard(
                      context,
                      _filteredCategories[index],
                      isDark,
                      primaryColor,
                      theme,
                    );
                  },
                );
              } else {
                // Tablet / Desktop Grid
                int columns = (width / 360).floor().clamp(2, 4);
                final spacing = 16.0;
                final itemWidth = (width - (spacing * (columns - 1))) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: _filteredCategories.map((cat) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildModernCategoryCard(
                        context,
                        cat,
                        isDark,
                        primaryColor,
                        theme,
                      ),
                    );
                  }).toList(),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildModernCategoryCard(
    BuildContext context,
    CategoryModel category,
    bool isDark,
    Color primaryColor,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor),
      ),
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showViewProductsDialog(category),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Thumbnail + Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Square Rounded Image or Icon Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: category.image.isNotEmpty
                          ? Image.network(
                              category.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildIconFallback(category.icon, primaryColor),
                            )
                          : _buildIconFallback(category.icon, primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Active Status Badge
                            GestureDetector(
                              onTap: () => _toggleStatus(category),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (category.status == 'Active' ? Colors.green : Colors.grey).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: (category.status == 'Active' ? Colors.green : Colors.grey).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: category.status == 'Active' ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      category.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: category.status == 'Active' ? Colors.green : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.description.isNotEmpty
                              ? category.description
                              : 'Delicious food item category.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Total Products Count Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${category.productCount} Products',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: theme.dividerColor),
              const SizedBox(height: 8),
              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: Colors.blue.shade600,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        tooltip: 'Edit Category',
                        onPressed: () => _showCategoryDialog(category),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: Colors.red.shade600,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        tooltip: 'Delete Category',
                        onPressed: () => _deleteCategory(category),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _showViewProductsDialog(category),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined, size: 14, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'View Products',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
