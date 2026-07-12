import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/menu_provider.dart';
import '../services/api_service.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Active, Hidden, Empty Categories
  String _selectedSort =
      'Newest'; // Alphabetical, Most Products, Newest, Oldest

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories(admin: true);
    });
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
      if (_selectedFilter == 'Inactive' && cat.status != 'Inactive')
        return false;
      if (_selectedFilter == 'Empty Categories' && cat.productCount > 0)
        return false;

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
    final descController = TextEditingController(
      text: category?.description ?? '',
    );
    final iconController = TextEditingController(
      text: category?.icon ?? 'fastfood',
    );
    final imageController = TextEditingController(text: category?.image ?? '');
    final sortOrderController = TextEditingController(
      text: category?.sortOrder.toString() ?? '0',
    );
    String status = category?.status ?? 'Active';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Category' : 'Add Category'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Short Description',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: iconController,
                        decoration: const InputDecoration(
                          labelText:
                              'Material Icon Name (e.g. fastfood, local_pizza)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: imageController,
                        decoration: const InputDecoration(
                          labelText: 'Banner Image URL (Optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: sortOrderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Display Order',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ['Active', 'Inactive']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
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
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);

                    try {
                      final sortOrder =
                          int.tryParse(sortOrderController.text.trim()) ?? 0;
                      if (isEditing) {
                        await context
                            .read<CategoryProvider>()
                            .updateCategory(category.id, {
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
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
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
              title: const Text('Delete Category'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.productCount > 0
                          ? 'This category has ${category.productCount} product(s). Choose how to proceed.'
                          : 'Delete this category?',
                    ),
                    if (category.productCount > 0) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedDestinationId,
                        decoration: const InputDecoration(
                          labelText: 'Move products to',
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
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      await context.read<CategoryProvider>().updateStatus(
        category.id,
        newStatus,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final provider = context.watch<CategoryProvider>();
    final categories = provider.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu Categories',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage restaurant menu categories and organize products efficiently.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Category'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E26) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search category...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2A2A35)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              // Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A35)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon: const Icon(Icons.filter_list, size: 20),
                    items: ['All', 'Active', 'Inactive', 'Empty Categories']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFilter = val);
                    },
                  ),
                ),
              ),
              // Sort
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A35)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    icon: const Icon(Icons.sort, size: 20),
                    items: ['Alphabetical', 'Most Products', 'Newest', 'Oldest']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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

        // Grid
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
              padding: const EdgeInsets.all(48.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error != null
                        ? 'Failed to load categories: ${provider.error}'
                        : 'No categories found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.read<CategoryProvider>().loadCategories(admin: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Open debug admin route in browser (helpful when running locally)
                        },
                        icon: const Icon(Icons.bug_report_outlined),
                        label: const Text('Debug'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 1;
              if (constraints.maxWidth >= 1200)
                columns = 4;
              else if (constraints.maxWidth >= 800)
                columns = 3;
              else if (constraints.maxWidth >= 600)
                columns = 2;

              final spacing = 20.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _filteredCategories.map((cat) {
                  return SizedBox(
                    width: itemWidth,
                    child: _buildCategoryCard(cat, isDark, primaryColor),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCategoryCard(
    CategoryModel category,
    bool isDark,
    Color primaryColor,
  ) {
    // Dynamic icon parsing
    IconData getIcon(String iconName) {
      // Map basic strings to material icons (expand as needed)
      switch (iconName.toLowerCase()) {
        case 'local_pizza':
        case 'pizza':
          return Icons.local_pizza;
        case 'lunch_dining':
        case 'burger':
          return Icons.lunch_dining;
        case 'local_cafe':
        case 'drinks':
          return Icons.local_cafe;
        case 'icecream':
        case 'dessert':
          return Icons.icecream;
        case 'set_meal':
          return Icons.set_meal;
        default:
          return Icons.fastfood;
      }
    }

    Color getStatusColor() {
      if (category.status == 'Active') return Colors.green;
      if (category.status == 'Hidden') return Colors.orange;
      return Colors.grey;
    }

    final createdAtStr = "${category.createdAt.year}-${category.createdAt.month.toString().padLeft(2, '0')}-${category.createdAt.day.toString().padLeft(2, '0')}";

    return Card(
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: isDark ? BorderSide(color: Colors.white.withOpacity(0.05)) : BorderSide.none,
      ),
      color: isDark ? const Color(0xFF1E1E26) : Colors.white,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Unified Top Banner Area (Image + Icon + Badge)
          SizedBox(
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (category.image.isNotEmpty)
                  Image.network(
                    category.image,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, trace) => Container(
                      color: primaryColor.withOpacity(0.1),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.15),
                          primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                // Overlay Gradient for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Center Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(
                      getIcon(category.icon),
                      size: 32,
                      color: primaryColor,
                    ),
                  ),
                ),
                // Active Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.status == 'Active' ? Icons.check_circle : Icons.visibility_off,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Created Date Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Added $createdAtStr',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Content Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${category.productCount} Products',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  category.description.isNotEmpty
                      ? category.description
                      : 'No description provided.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: Colors.blue,
                          tooltip: 'Edit Category',
                          onPressed: () => _showCategoryDialog(category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.red,
                          tooltip: 'Delete Category',
                          onPressed: () => _deleteCategory(category),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final products = context.read<MenuProvider>().rawMenuItems.where((p) => p.category == category.name).toList();
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('${category.name} Products'),
                            content: SizedBox(
                              width: 400,
                              height: 300,
                              child: products.isEmpty 
                                  ? const Center(child: Text('No products in this category.'))
                                  : ListView.builder(
                                      itemCount: products.length,
                                      itemBuilder: (ctx, i) => ListTile(
                                        leading: const Icon(Icons.fastfood),
                                        title: Text(products[i].name),
                                        subtitle: Text('${products[i].price} DH'),
                                      ),
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
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Products'),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
