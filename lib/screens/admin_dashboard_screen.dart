import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math' as math;
import '../providers/client_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/branch_provider.dart';
import '../providers/category_provider.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../providers/menu_provider.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../models/branch.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';
import '../config/app_config.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_order_card.dart';
import '../widgets/admin_chart_card.dart';
import 'admin_customers_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_product_details_screen.dart';
import 'admin_qr_details_screen.dart';
import 'admin_offer_details_screen.dart';
import 'admin_offer_form_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const routeName = '/admin-dashboard';

  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _currentTab = 'Dashboard';
  final List<String> _tabHistory = ['Dashboard'];
  String _searchQuery = '';
  String _offerSearchQuery = '';
  String? _updatingOrderId;
  String _selectedOrderStatusFilter = 'all';
  String _selectedProductCategory = 'All';
  String _selectedOfferCategory = 'All';
  String _selectedProductStatus = 'All';
  String _selectedOfferStatusFilter = 'All';
  final Map<String, bool> _pendingOfferToggle = {};

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _offerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchOrders();
      context.read<BranchProvider>().loadBranches();
      context.read<MenuProvider>().loadMenu(null);
      context.read<CategoryProvider>().loadCategories(admin: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _offerSearchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
  }

  void _onBackPressed() {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    
    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        _currentTab = _tabHistory.last;
        _searchQuery = '';
        _searchController.clear();
      });
    } else {
      if (!isDesktop) {
        final scaffoldState = Scaffold.maybeOf(context);
        if (scaffoldState != null) {
          if (scaffoldState.isDrawerOpen) {
            scaffoldState.closeDrawer();
          } else {
            scaffoldState.openDrawer();
          }
        }
      }
    }
  }

  List<MenuItem> _uniqueProductList(List<MenuItem> items) {
    final ids = <String>{};
    final keys = <String>{};

    return items.where((item) {
      final normalizedKey =
          '${item.name.toLowerCase().trim()}|${item.category.toLowerCase().trim()}';
      if (ids.contains(item.id) || keys.contains(normalizedKey)) {
        return false;
      }
      ids.add(item.id);
      keys.add(normalizedKey);
      return true;
    }).toList();
  }

  List<MenuItem> _filterAdminProducts(List<MenuItem> rawItems) {
    final search = _searchQuery.toLowerCase();
    return _uniqueProductList(rawItems).where((item) {
      if (_selectedProductCategory != 'All' &&
          item.category != _selectedProductCategory) {
        return false;
      }

      if (_selectedProductStatus == 'In Stock' && !item.isAvailable) {
        return false;
      }
      if (_selectedProductStatus == 'Out of Stock' && item.isAvailable) {
        return false;
      }

      if (search.isNotEmpty) {
        return item.name.toLowerCase().contains(search) ||
            item.category.toLowerCase().contains(search);
      }
      return true;
    }).toList();
  }

  bool _isOfferCurrentlyActive(MenuItem item) {
    final now = DateTime.now();
    if (!item.hasOffer || !item.isOfferActive || item.offerPrice == null) {
      return false;
    }
    if (item.offerStartDate != null && item.offerStartDate!.isAfter(now)) {
      return false;
    }
    if (item.offerExpiresAt != null && !now.isBefore(item.offerExpiresAt!)) {
      return false;
    }
    return true;
  }

  bool _isOfferExpired(MenuItem item) {
    final now = DateTime.now();
    return item.hasOffer &&
        item.offerExpiresAt != null &&
        now.isAfter(item.offerExpiresAt!);
  }

  bool _isOfferScheduled(MenuItem item) {
    final now = DateTime.now();
    return item.hasOffer &&
        item.isOfferActive &&
        item.offerStartDate != null &&
        item.offerStartDate!.isAfter(now) &&
        !_isOfferExpired(item);
  }

  bool _isOfferDisabled(MenuItem item) {
    return item.hasOffer && !item.isOfferActive;
  }

  List<MenuItem> _filterAdminOffers(List<MenuItem> rawItems) {
    final search = _offerSearchQuery.toLowerCase();
    return rawItems.where((item) {
      if (!item.hasOffer) return false;
      if (_selectedOfferCategory != 'All' &&
          item.category != _selectedOfferCategory) {
        return false;
      }

      final isActive = _isOfferCurrentlyActive(item);
      final isExpired = _isOfferExpired(item);
      final isScheduled = _isOfferScheduled(item);
      final isDisabled = _isOfferDisabled(item);

      if (_selectedOfferStatusFilter == 'Active' && !isActive) return false;
      if (_selectedOfferStatusFilter == 'Scheduled' && !isScheduled) return false;
      if (_selectedOfferStatusFilter == 'Expired' && !isExpired) return false;
      if (_selectedOfferStatusFilter == 'Disabled' && !isDisabled) return false;

      if (search.isNotEmpty) {
        final lowerName = item.name.toLowerCase();
        final lowerCategory = item.category.toLowerCase();
        final lowerTitle = (item.offerTitle ?? '').toLowerCase();
        final lowerLabel = (item.offerLabel ?? '').toLowerCase();
        return lowerName.contains(search) ||
            lowerCategory.contains(search) ||
            lowerTitle.contains(search) ||
            lowerLabel.contains(search);
      }
      return true;
    }).toList();
  }

  String _formatSimpleDate(DateTime? date) {
    if (date == null) return 'Open';
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Widget _buildOfferStatusChip(
    String title,
    int count,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFEF3E9) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? Colors.deepOrange : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.deepOrange : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.deepOrange.withOpacity(0.12)
                    : Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.deepOrange.shade700 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProductDialog(
    BuildContext context, {
    MenuItem? editingItem,
  }) async {
    final activeCategories = context.read<CategoryProvider>().categories
        .where((c) => c.status == 'Active')
        .map((c) => c.name)
        .toList();
    final categoryOptions = List<String>.from(activeCategories);
    if (editingItem != null && editingItem.category.isNotEmpty && !categoryOptions.contains(editingItem.category)) {
      categoryOptions.add(editingItem.category);
    }
    if (categoryOptions.isEmpty) {
      categoryOptions.add('Uncategorized');
    }

    final nameController = TextEditingController(text: editingItem?.name ?? '');
    final descriptionController = TextEditingController(
      text: editingItem?.description ?? '',
    );
    final priceController = TextEditingController(
      text: editingItem != null ? editingItem.price.toStringAsFixed(0) : '',
    );
    final imageUrlController = TextEditingController(
      text: editingItem?.imageUrl ?? '',
    );
    final caloriesController = TextEditingController(
      text: editingItem?.calories.toString() ?? '0',
    );
    final proteinController = TextEditingController(
      text: editingItem?.protein.toString() ?? '0',
    );
    final tagsController = TextEditingController(
      text: editingItem?.tags.join(', ') ?? '',
    );
    String selectedCategory = editingItem?.category ?? categoryOptions.first;
    bool isAvailable = editingItem?.isAvailable ?? true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                editingItem == null ? 'Add Product' : 'Edit Product',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live Image Preview Box
                    if (imageUrlController.text.isNotEmpty)
                      Container(
                        height: 120,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            imageUrlController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon: const Icon(Icons.fastfood_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory.isEmpty || !categoryOptions.contains(selectedCategory) ? null : selectedCategory,
                      items: categoryOptions
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price (DH)',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageUrlController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Image URL',
                        prefixIcon: const Icon(Icons.image_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: caloriesController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Calories (kcal)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: proteinController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Protein (g)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tagsController,
                      decoration: InputDecoration(
                        labelText: 'Tags (comma separated)',
                        prefixIcon: const Icon(Icons.label_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available in Menu', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: isAvailable,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) =>
                          setDialogState(() => isAvailable = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final description = descriptionController.text.trim();
                    final imageUrl = imageUrlController.text.trim();
                    final price =
                        double.tryParse(priceController.text.trim()) ?? 0;
                    final calories =
                        int.tryParse(caloriesController.text.trim()) ?? 0;
                    final protein =
                        int.tryParse(proteinController.text.trim()) ?? 0;
                    final tags = tagsController.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();

                    if (name.isEmpty ||
                        selectedCategory.isEmpty ||
                        price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill product name, category, and price.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      if (editingItem == null) {
                        await ApiService.createMenuItem(
                          name: name,
                          description: description,
                          price: price,
                          imageUrl: imageUrl,
                          category: selectedCategory,
                          calories: calories,
                          protein: protein,
                          tags: tags,
                          isAvailable: isAvailable,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product added successfully.'),
                          ),
                        );
                      } else {
                        await ApiService.updateMenuItem(
                          id: editingItem.id,
                          name: name,
                          description: description,
                          price: price,
                          imageUrl: imageUrl,
                          category: selectedCategory,
                          calories: calories,
                          protein: protein,
                          tags: tags,
                          isAvailable: isAvailable,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product updated successfully.'),
                          ),
                        );
                      }

                      await context.read<MenuProvider>().loadMenu(null);
                      Navigator.of(dialogContext).pop();
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save product: $error'),
                        ),
                      );
                    }
                  },
                  child: Text(editingItem == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteProduct(
    BuildContext context,
    MenuItem product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Delete "${product.name}" from the menu? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteMenuItem(product.id);
      await context.read<MenuProvider>().loadMenu(null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $error')),
      );
    }
  }

  Future<void> _refreshMenuItems() async {
    await context.read<MenuProvider>().loadMenu(null);
  }

  Future<void> _showOfferDialog(
    BuildContext context, {
    MenuItem? editingOffer,
  }) async {
    final menuProvider = context.read<MenuProvider>();
    final allProducts = menuProvider.rawMenuItems;
    final eligibleProducts = allProducts
        .where((item) => !item.hasOffer || item.id == editingOffer?.id)
        .toList();

    if (eligibleProducts.isEmpty && editingOffer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No eligible products available to add an offer.'),
        ),
      );
      return;
    }

    String selectedProductId = editingOffer?.id ?? eligibleProducts.first.id;
    final offerTitleController = TextEditingController(
      text: editingOffer?.offerTitle ?? '',
    );
    final offerDescriptionController = TextEditingController(
      text: editingOffer?.offerDescription ?? '',
    );
    final oldPriceController = TextEditingController(
      text: editingOffer?.oldPrice?.toStringAsFixed(0) ?? '',
    );
    final offerPriceController = TextEditingController(
      text: editingOffer?.offerPrice?.toStringAsFixed(0) ?? '',
    );
    final offerLabelController = TextEditingController(
      text: editingOffer?.offerLabel ?? '',
    );
    DateTime startDate =
        editingOffer?.offerStartDate?.toLocal() ?? DateTime.now();
    DateTime expiresAt =
        editingOffer?.offerExpiresAt?.toLocal() ??
        DateTime.now().add(const Duration(days: 7));
    bool isActive = editingOffer?.isOfferActive ?? true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(editingOffer == null ? 'Add Offer' : 'Edit Offer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (editingOffer == null)
                      DropdownButtonFormField<String>(
                        value: selectedProductId,
                        decoration: const InputDecoration(labelText: 'Product'),
                        items: eligibleProducts
                            .map(
                              (product) => DropdownMenuItem(
                                value: product.id,
                                child: Text(product.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedProductId = value);
                          }
                        },
                      ),
                    if (editingOffer != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                editingOffer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              editingOffer.category,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: offerTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Offer title',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: offerDescriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Offer description',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: oldPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Old price (DH)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: offerPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Offer price (DH)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: offerLabelController,
                      decoration: const InputDecoration(
                        labelText: 'Offer label',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Start: ${_formatSimpleDate(startDate)}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: startDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 2),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => startDate = picked);
                            }
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Expires: ${_formatSimpleDate(expiresAt)}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: expiresAt,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 2),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => expiresAt = picked);
                            }
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active offer'),
                      value: isActive,
                      onChanged: (value) =>
                          setDialogState(() => isActive = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = offerTitleController.text.trim();
                    final description = offerDescriptionController.text.trim();
                    final oldPrice =
                        double.tryParse(oldPriceController.text.trim()) ?? 0;
                    final offerPrice =
                        double.tryParse(offerPriceController.text.trim()) ?? 0;
                    final label = offerLabelController.text.trim();

                    if (title.isEmpty ||
                        oldPrice <= 0 ||
                        offerPrice <= 0 ||
                        offerPrice >= oldPrice) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fill valid offer title and prices.'),
                        ),
                      );
                      return;
                    }

                    try {
                      if (editingOffer == null) {
                        await ApiService.createOffer(
                          productId: selectedProductId,
                          offerTitle: title,
                          offerDescription: description,
                          oldPrice: oldPrice,
                          offerPrice: offerPrice,
                          offerLabel: label.isNotEmpty ? label : null,
                          offerStartDate: startDate,
                          offerExpiresAt: expiresAt,
                          isOfferActive: isActive,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Offer created successfully.'),
                          ),
                        );
                      } else {
                        await ApiService.updateOffer(
                          productId: editingOffer.id,
                          offerTitle: title,
                          offerDescription: description,
                          oldPrice: oldPrice,
                          offerPrice: offerPrice,
                          offerLabel: label.isNotEmpty ? label : null,
                          offerStartDate: startDate,
                          offerExpiresAt: expiresAt,
                          isOfferActive: isActive,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Offer updated successfully.'),
                          ),
                        );
                      }

                      await _refreshMenuItems();
                      Navigator.of(dialogContext).pop();
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save offer: $error')),
                      );
                    }
                  },
                  child: Text(
                    editingOffer == null ? 'Add Offer' : 'Save Offer',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteOffer(
    BuildContext context,
    MenuItem offerItem,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Offer'),
          content: Text(
            'Delete offer for "${offerItem.name}"? This will remove the promotional details from the product.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteOffer(offerItem.id);
      await _refreshMenuItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer deleted successfully.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete offer: $error')));
    }
  }

  Future<void> _toggleOfferActive(
    BuildContext context,
    MenuItem offerItem,
    bool isActive,
  ) async {
    setState(() {
      _pendingOfferToggle[offerItem.id] = isActive;
    });

    try {
      await ApiService.toggleOffer(productId: offerItem.id, isActive: isActive);
      await _refreshMenuItems();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'Offer activated successfully'
                : 'Offer deactivated successfully',
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update offer status: $error')),
      );
    } finally {
      setState(() {
        _pendingOfferToggle.remove(offerItem.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final adminProvider = context.watch<AdminProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final branchProvider = context.watch<BranchProvider>();

    if (!adminProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/admin-login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
          ),
        ),
      );
    }

    // Build Drawer / Sidebar logout function
    final VoidCallback logoutAction = () async {
      final result = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out?'),
          content: const Text('Choose sign out option:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 1),
              child: const Text('Sign Out'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 2),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sign Out (All Sessions)'),
            ),
          ],
        ),
      );

      if (result == 1) {
        await adminProvider.logout();
        if (mounted) Navigator.of(context).pushReplacementNamed('/admin-login');
      } else if (result == 2) {
        await adminProvider.logout(clearAll: true);
        try {
          await context.read<ClientProvider>().logout();
        } catch (_) {}
        if (mounted) Navigator.of(context).pushReplacementNamed('/admin-login');
      }
    };

    // Sidebar selection handler
    final Function(String) itemSelectedAction = (item) {
      if (_currentTab != item) {
        setState(() {
          _tabHistory.remove(item);
          _tabHistory.add(item);
          _currentTab = item;
          _searchQuery = '';
          _searchController.clear();
        });
      }
      // Close drawer on mobile if open without popping the admin route stack
      if (!isDesktop) {
        Scaffold.maybeOf(context)?.closeDrawer();
      }
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        _onBackPressed();
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: !isDesktop
            ? AppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                centerTitle: false,
                titleSpacing: 0,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, size: 28),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                title: Text(
                  _currentTab,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    tooltip: 'More Actions',
                    onSelected: (val) {
                      if (val == 'refresh') {
                        context.read<AdminProvider>().fetchOrders();
                        context.read<BranchProvider>().loadBranches();
                        context.read<MenuProvider>().loadMenu(null);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data refreshed'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else if (val == 'branch') {
                        Navigator.of(context).pushNamedAndRemoveUntil('/branch-selection', (route) => false);
                      } else if (val == 'logout') {
                        logoutAction();
                      } else if (val == 'drawer') {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Refresh Data'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'branch',
                        child: Row(
                          children: [
                            Icon(Icons.storefront_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Change Branch'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'drawer',
                        child: Row(
                          children: [
                            Icon(Icons.menu_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Open Navigation Drawer'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Logout', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                shape: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              )
            : null,
        drawer: !isDesktop
            ? Drawer(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
                ),
                child: AdminSidebar(
                  activeItem: _currentTab,
                  onItemSelected: itemSelectedAction,
                  onLogout: logoutAction,
                ),
              )
            : null,
        body: Row(
          children: [
            // Sidebar for Desktop
            if (isDesktop)
              AdminSidebar(
                activeItem: _currentTab,
                onItemSelected: itemSelectedAction,
                onLogout: logoutAction,
              ),
            // Content Area
            Expanded(
              child: Column(
                children: [
                  // Top Bar
                  if (isDesktop) _buildTopBar(context, adminProvider, isDesktop),

                // Content Body
                Expanded(
                  child: adminProvider.isLoading && adminProvider.orders.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.deepOrange,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await adminProvider.fetchOrders();
                            await branchProvider.loadBranches();
                            await menuProvider.loadMenu(null);
                          },
                          color: Colors.deepOrange,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            child: _buildBody(
                              context,
                              adminProvider,
                              menuProvider,
                              branchProvider,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // -------------------------------------------------------------------
  // Header Top Bar
  // -------------------------------------------------------------------
  Widget _buildTopBar(
    BuildContext context,
    AdminProvider adminProvider,
    bool isDesktop,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final adminName =
        adminProvider.adminInfo?['fullName'] ??
        adminProvider.adminInfo?['name'] ??
        'Samantha';

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Drawer Trigger on Mobile
          if (!isDesktop) ...[
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Search Field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search here...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Icons & Profile
          Row(
            children: [
              // Notification Icon
              _buildIconButton(
                icon: Icons.notifications_none_outlined,
                badgeCount: 3,
                color: Colors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications screen')),
                  );
                },
              ),
              const SizedBox(width: 12),

              // Refresh Button
              _buildIconButton(
                icon: Icons.refresh_rounded,
                color: primaryColor,
                onTap: () {
                  context.read<AdminProvider>().fetchOrders();
                  context.read<BranchProvider>().loadBranches();
                  context.read<MenuProvider>().loadMenu(null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dashboard data synchronized'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),

              // Vertical Divider
              Container(
                width: 1,
                height: 32,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              const SizedBox(width: 16),

              // Profile area
              Row(
                children: [
                  if (MediaQuery.of(context).size.width >= 600) ...[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Hello, $adminName',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E1E26),
                          ),
                        ),
                        Text(
                          'Admin Manager',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                  ],
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 20, color: color),
            if (badgeCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Dynamic Tab Router
  // -------------------------------------------------------------------
  Widget _buildBody(
    BuildContext context,
    AdminProvider adminProvider,
    MenuProvider menuProvider,
    BranchProvider branchProvider,
  ) {
    switch (_currentTab) {
      case 'Dashboard':
        return _buildDashboardTab(context, adminProvider, menuProvider);
      case 'Orders':
        return _buildOrdersTab(context, adminProvider);
      case 'Products':
        return _buildProductsTab(context, menuProvider);
      case 'Categories':
        return const SingleChildScrollView(child: AdminCategoriesScreen());
      case 'Customers':
        return _buildCustomersTab(context, adminProvider);
      case 'Offers':
        return _buildOffersTab(context, menuProvider, branchProvider);
      case 'QR Menu':
        return _buildQRMenuTab(context, branchProvider);
      case 'Analytics':
        return _buildAnalyticsTab(context, adminProvider, branchProvider);
      default:
        return _buildDashboardTab(context, adminProvider, menuProvider);
    }
  }

  // -------------------------------------------------------------------
  // Tab 1: Dashboard View
  // -------------------------------------------------------------------
  Widget _buildDashboardTab(
    BuildContext context,
    AdminProvider adminProvider,
    MenuProvider menuProvider,
  ) {
    // Aggregate stats
    final totalProducts = menuProvider.rawMenuItems.length;
    final totalCustomers = adminProvider.orders
        .map((o) => o.phone)
        .toSet()
        .length;

    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop) ...[
          // Title banner
          Text(
            'Dashboard Overview',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Hi welcome back. Wassim Food operational statistics at a glance.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
        ],

        // Statistics Grid
        // Statistics Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            int crossAxisCount = (maxWidth / 250).ceil();
            if (crossAxisCount < 1) crossAxisCount = 1;
            
            final double spacing = 16.0;
            final double itemWidth = (maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

            final children = [
              AdminStatCard(
                title: 'Total Orders',
                value: '${adminProvider.totalOrdersCount}',
                icon: Icons.receipt_long_rounded,
                color: Colors.blue,
                trend: '4%',
                isTrendPositive: true,
              ),
              AdminStatCard(
                title: 'Pending Orders',
                value: '${adminProvider.pendingOrdersCount}',
                icon: Icons.hourglass_empty_rounded,
                color: Colors.orange,
                trend: '12%',
                isTrendPositive: false,
              ),
              AdminStatCard(
                title: 'Delivered Orders',
                value: '${adminProvider.deliveredOrdersCount}',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green,
                trend: '8%',
                isTrendPositive: true,
              ),
              AdminStatCard(
                title: 'Total Revenue',
                value: CurrencyFormatter.formatDH(adminProvider.totalRevenue),
                icon: Icons.payments_outlined,
                color: Colors.teal,
                trend: '15%',
                isTrendPositive: true,
              ),
              AdminStatCard(
                title: 'Total Customers',
                value: '$totalCustomers',
                icon: Icons.people_outline_rounded,
                color: Colors.purple,
                trend: '6%',
                isTrendPositive: true,
              ),
              AdminStatCard(
                title: 'Total Products',
                value: '$totalProducts',
                icon: Icons.restaurant_menu_rounded,
                color: Colors.deepOrange,
                trend: '2%',
                isTrendPositive: true,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: children
                  .map((child) => SizedBox(width: itemWidth, child: child))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 28),

        // Charts Section
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final isSmall = width < 1100;
            if (isSmall) {
              return Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: AdminChartCard(
                      title: 'Orders Distribution',
                      child: AdminStatusPieChart(
                        pending: adminProvider.pendingOrdersCount,
                        preparing: adminProvider.preparingOrdersCount,
                        delivering: adminProvider.deliveringOrdersCount,
                        delivered: adminProvider.deliveredOrdersCount,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: AdminChartCard(
                      title: 'Revenue Summary',
                      child: AdminRevenueBarChart(
                        totalRevenue: adminProvider.totalRevenue,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 240,
                      child: AdminChartCard(
                        title: 'Orders Distribution',
                        child: AdminStatusPieChart(
                          pending: adminProvider.pendingOrdersCount,
                          preparing: adminProvider.preparingOrdersCount,
                          delivering: adminProvider.deliveringOrdersCount,
                          delivered: adminProvider.deliveredOrdersCount,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 240,
                      child: AdminChartCard(
                        title: 'Revenue Summary',
                        child: AdminRevenueBarChart(
                          totalRevenue: adminProvider.totalRevenue,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 28),

        // Recent Orders Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders Overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentTab = 'Orders';
                });
              },
              child: const Text('View All Orders'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Render latest 3 orders
        if (adminProvider.orders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No orders found.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(adminProvider.orders.length, 3),
            itemBuilder: (context, index) {
              final order = adminProvider.orders[index];
              return _buildDashboardOrderCard(context, order, adminProvider);
            },
          ),
      ],
    );
  }

  Widget _buildDashboardOrderCard(
    BuildContext context,
    Order order,
    AdminProvider adminProvider,
  ) {
    return AdminOrderCard(
      order: order,
      isUpdating: adminProvider.isLoading && _updatingOrderId == order.id,
      onUpdateStatus: (newStatus) async {
        setState(() {
          _updatingOrderId = order.id;
        });
        final success = await adminProvider.updateOrderStatus(
          order.id,
          newStatus,
        );
        setState(() {
          _updatingOrderId = null;
        });
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                adminProvider.error ?? 'Failed to update order status',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  // -------------------------------------------------------------------
  // Tab 2: Orders View
  // -------------------------------------------------------------------
  Widget _buildOrdersTab(BuildContext context, AdminProvider adminProvider) {
    final filteredOrders = adminProvider.orders.where((o) {
      // 1. Status Filter
      if (_selectedOrderStatusFilter != 'all' &&
          o.status != _selectedOrderStatusFilter) {
        return false;
      }
      // 2. Search query (matches Customer Name, Phone, or ID)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = o.customerName.toLowerCase().contains(query);
        final phoneMatch = o.phone.contains(query);
        final idMatch = o.id.toLowerCase().contains(query);
        return nameMatch || phoneMatch || idMatch;
      }
      return true;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Restaurant Hero Banner Card (Attached Reference Design)
        Container(
          width: double.infinity,
          height: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.9),
                primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background cutlery/restaurant illustration
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 180,
                  color: Colors.white.withOpacity(0.12),
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
                            Icons.fastfood_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Wassim Food - Plaza',
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
                        const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Morocco • Main Branch',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '4.8 (224 ratings)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                '${filteredOrders.length} Orders',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

        // 2. Main Online Orders Filter Button
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Online Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SizedBox(height: 20),

        // 2. Status Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ['all', 'pending', 'preparing', 'delivering', 'delivered', 'cancelled']
                .map((status) {
                  final isSelected = _selectedOrderStatusFilter == status;
                  String display = status[0].toUpperCase() + status.substring(1);
                  if (status == 'all') display = 'All Orders';

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(display),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedOrderStatusFilter = status;
                          });
                        }
                      },
                      selectedColor: primaryColor.withOpacity(0.15),
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
                })
                .toList(),
          ),
        ),
        const SizedBox(height: 20),

        // List
        if (filteredOrders.isEmpty)
          Padding(
            padding: const EdgeInsets.all(48.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No orders match the selected criteria.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              return _buildDashboardOrderCard(context, order, adminProvider);
            },
          ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Tab 3: Products View
  // -------------------------------------------------------------------
  Widget _buildProductsTab(
    BuildContext context,
    MenuProvider menuProvider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final items = _filterAdminProducts(menuProvider.rawMenuItems);
    final categories = <String>{'All'};
    categories.addAll(
      menuProvider.rawMenuItems
          .map((item) => item.category)
          .where((value) => value.isNotEmpty),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Restaurant Hero Banner (Reference Design Header)
        Container(
          width: double.infinity,
          height: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.9),
                primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
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
                  Icons.restaurant_menu_rounded,
                  size: 180,
                  color: Colors.white.withOpacity(0.12),
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
                            Icons.fastfood_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Wassim Food - Plaza',
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
                        const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Morocco • Main Branch',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '4.8 (224 ratings)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${menuProvider.rawMenuItems.length} Items Total',
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

        // 2. Search & Add Product Action Row
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
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
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
                onPressed: () => _showProductDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Product'),
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
        const SizedBox(height: 20),

        // 3. Category Horizontal Scrolling Tabs (Reference Layout)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Menu Items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedProductCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedProductCategory = cat;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 3,
                            width: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4. Quick Availability & Type Filter Pills (Reference Layout: Veg / Non-Veg / Stock)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterPill(context, 'All', 'All', isDark, primaryColor),
              const SizedBox(width: 8),
              _buildFilterPill(context, 'In Stock', 'In Stock 🟢', isDark, primaryColor),
              const SizedBox(width: 8),
              _buildFilterPill(context, 'Out of Stock', 'Out of Stock 🔴', isDark, primaryColor),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 5. Product List / Grid (Reference Layout: Crisp cards with image left + title, info, price in DH, buttons)
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fastfood_outlined,
                    size: 48,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products found in this category.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final product = items[index];
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminProductDetailsScreen(
                          product: product,
                          onEdit: (p) => _showProductDialog(context, editingItem: p),
                          onDelete: (p) => _confirmDeleteProduct(context, p),
                          onToggleAvailability: (p, avail) async {
                            await ApiService.updateMenuItem(
                              id: p.id,
                              name: p.name,
                              description: p.description,
                              price: p.price,
                              imageUrl: p.imageUrl,
                              category: p.category,
                              isAvailable: avail,
                            );
                            await context.read<MenuProvider>().loadMenu(null);
                          },
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image Thumbnail (Square Rounded)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 90,
                            height: 90,
                            child: product.imageUrl.isNotEmpty
                                ? Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: primaryColor.withOpacity(0.1),
                                      child: Icon(Icons.fastfood, size: 36, color: primaryColor),
                                    ),
                                  )
                                : Container(
                                    color: primaryColor.withOpacity(0.1),
                                    child: Icon(Icons.fastfood, size: 36, color: primaryColor),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Info Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (product.isAvailable ? Colors.green : Colors.red).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      product.isAvailable ? 'In Stock' : 'Out of Stock',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: product.isAvailable ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.description.isNotEmpty
                                    ? product.description
                                    : 'Fresh loaded Wassim Food special recipe.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatDH(product.effectivePrice),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: primaryColor,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _showProductDialog(context, editingItem: product),
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit Product',
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        onPressed: () => _confirmDeleteProduct(context, product),
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Delete Product',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterPill(
    BuildContext context,
    String value,
    String label,
    bool isDark,
    Color primaryColor,
  ) {
    final isSelected = _selectedProductStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedProductStatus = value;
          });
        }
      },
      selectedColor: primaryColor.withOpacity(0.15),
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
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    String value,
    String label,
    bool isDark,
    Color primaryColor,
  ) {
    final isSelected = _selectedProductStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedProductStatus = value;
          });
        }
      },
      selectedColor: primaryColor.withOpacity(0.15),
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
    );
  }



  // -------------------------------------------------------------------
  // Tab 5: Customers View
  // -------------------------------------------------------------------
  Widget _buildCustomersTab(BuildContext context, AdminProvider adminProvider) {
    return const SingleChildScrollView(child: AdminCustomersScreen());
  }

  // -------------------------------------------------------------------
  // Tab 6: Offers View
  // -------------------------------------------------------------------
  Widget _buildOffersTab(
    BuildContext context,
    MenuProvider menuProvider,
    BranchProvider branchProvider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final allOffers = menuProvider.rawMenuItems
        .where((item) => item.hasOffer)
        .toList();
    final offers = _filterAdminOffers(menuProvider.rawMenuItems);
    final categories = <String>{'All'};
    categories.addAll(
      menuProvider.rawMenuItems
          .map((item) => item.category)
          .where((value) => value.isNotEmpty),
    );

    final totalActive = allOffers.where(_isOfferCurrentlyActive).length;
    final totalExpired = allOffers.where(_isOfferExpired).length;
    final totalScheduled = allOffers.where(_isOfferScheduled).length;
    final totalDisabled = allOffers.where(_isOfferDisabled).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Premium Hero Header Banner
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
                  Icons.local_offer_rounded,
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
                            Icons.local_offer_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Wassim Food Offers',
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
                        const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${branchProvider.selectedBranch?.name ?? "Maarif Branch"} • ${branchProvider.selectedBranch?.city.isNotEmpty == true ? branchProvider.selectedBranch!.city : "Casablanca"}',
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
                        const Icon(Icons.discount_rounded, color: Color(0xFFFFC107), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${allOffers.length} Total Offers',
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
                            '$totalActive Active • $totalScheduled Scheduled • $totalExpired Expired',
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

        // 2. Search & Add Offer Action Row
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
                  controller: _offerSearchController,
                  onChanged: (val) => setState(() => _offerSearchQuery = val.trim()),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search offers by title, product, category...',
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
                onPressed: () async {
                  await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminOfferFormScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Offer'),
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

        // 3. Status Filter Chips (All, Active, Scheduled, Expired, Disabled)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildModernOfferStatusChip('All', allOffers.length, isDark, primaryColor),
              const SizedBox(width: 8),
              _buildModernOfferStatusChip('Active', totalActive, isDark, Colors.green),
              const SizedBox(width: 8),
              _buildModernOfferStatusChip('Scheduled', totalScheduled, isDark, Colors.orange),
              const SizedBox(width: 8),
              _buildModernOfferStatusChip('Expired', totalExpired, isDark, Colors.red),
              const SizedBox(width: 8),
              _buildModernOfferStatusChip('Disabled', totalDisabled, isDark, Colors.grey),
              const SizedBox(width: 12),
              // Category Filter Dropdown Pill
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
                    value: _selectedOfferCategory,
                    icon: const Icon(Icons.category_outlined, size: 16),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c == 'All' ? 'All Categories' : c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedOfferCategory = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 4. Offers List / Grid
        if (menuProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(),
            ),
          )
        else if (offers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 48,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No offers found matching criteria.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
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
              if (width < 700) {
                // Mobile single column list
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: offers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _buildModernOfferCard(context, offers[index], isDark, primaryColor, theme);
                  },
                );
              } else {
                // Tablet / Desktop Grid
                int columns = (width / 420).floor().clamp(2, 3);
                final spacing = 16.0;
                final itemWidth = (width - (spacing * (columns - 1))) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: offers.map((offer) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildModernOfferCard(context, offer, isDark, primaryColor, theme),
                    );
                  }).toList(),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildModernOfferStatusChip(
    String filterValue,
    int count,
    bool isDark,
    Color activeColor,
  ) {
    final isSelected = _selectedOfferStatusFilter == filterValue;
    return ChoiceChip(
      label: Text('$filterValue ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedOfferStatusFilter = filterValue);
        }
      },
      selectedColor: activeColor.withValues(alpha: 0.15),
      checkmarkColor: activeColor,
      labelStyle: TextStyle(
        color: isSelected ? activeColor : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        fontSize: 12,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? activeColor : (isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
          width: 1,
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E26) : Colors.white,
    );
  }

  Widget _buildModernOfferCard(
    BuildContext context,
    MenuItem offer,
    bool isDark,
    Color primaryColor,
    ThemeData theme,
  ) {
    final isExpired = _isOfferExpired(offer);
    final isScheduled = _isOfferScheduled(offer);
    final isActive = _isOfferCurrentlyActive(offer);

    String statusLabel = 'Disabled';
    Color statusColor = Colors.grey;

    if (!offer.isOfferActive) {
      statusLabel = 'Disabled';
      statusColor = Colors.grey;
    } else if (isExpired) {
      statusLabel = 'Expired';
      statusColor = Colors.red;
    } else if (isScheduled) {
      statusLabel = 'Scheduled';
      statusColor = Colors.orange;
    } else if (isActive) {
      statusLabel = 'Active';
      statusColor = Colors.green;
    }

    final oldP = offer.oldPrice ?? 0;
    final newP = offer.offerPrice ?? offer.effectivePrice;
    int discountPercent = 0;
    if (oldP > 0 && newP < oldP) {
      discountPercent = (((oldP - newP) / oldP) * 100).round();
    }

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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminOfferDetailsScreen(offer: offer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Image Thumbnail + Details + Top Right Edit/Delete
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Square Rounded Image (90x90)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: offer.imageUrl.isNotEmpty
                          ? Image.network(
                              offer.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: primaryColor.withValues(alpha: 0.1),
                                child: Icon(Icons.fastfood, size: 36, color: primaryColor),
                              ),
                            )
                          : Container(
                              color: primaryColor.withValues(alpha: 0.1),
                              child: Icon(Icons.fastfood, size: 36, color: primaryColor),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                offer.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: Colors.blue.shade600,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              tooltip: 'Edit Offer',
                              onPressed: () async {
                                await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminOfferFormScreen(editingOffer: offer),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              color: Colors.red.shade600,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              tooltip: 'Delete Offer',
                              onPressed: () => _confirmDeleteOffer(context, offer),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                offer.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Offer Title or description snippet
                        Text(
                          offer.offerTitle?.isNotEmpty == true
                              ? offer.offerTitle!
                              : (offer.offerDescription?.isNotEmpty == true ? offer.offerDescription! : 'Special Promotional Offer'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Price Row with Strikethrough Old Price, New Price, and Discount Badge
              Row(
                children: [
                  if (oldP > 0) ...[
                    Text(
                      CurrencyFormatter.formatDH(oldP),
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    CurrencyFormatter.formatDH(newP),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: primaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (discountPercent > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    )
                  else if (offer.offerLabel?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        offer.offerLabel!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, thickness: 1, color: theme.dividerColor),
              const SizedBox(height: 8),
              // Bottom Row: Dates + Modern Active Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start: ${_formatSimpleDate(offer.offerStartDate)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      Text(
                        'Expires: ${_formatSimpleDate(offer.offerExpiresAt)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pendingOfferToggle[offer.id] ?? offer.isOfferActive ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _pendingOfferToggle[offer.id] ?? offer.isOfferActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch.adaptive(
                          value: _pendingOfferToggle[offer.id] ?? offer.isOfferActive,
                          activeColor: primaryColor,
                          onChanged: (value) => _toggleOfferActive(context, offer, value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Tab 7: QR Menu View
  // -------------------------------------------------------------------
  // -------------------------------------------------------------------
  // Tab 7: QR Menu View
  // -------------------------------------------------------------------
  Widget _buildQRMenuTab(BuildContext context, BranchProvider branchProvider) {
    final branches = branchProvider.branches;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF8D4B38);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Hero Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8D4B38), Color(0xFF6E392A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6E392A).withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Translucent background illustration of cutlery/QR
                Positioned(
                  right: -24,
                  bottom: -24,
                  child: Opacity(
                    opacity: 0.12,
                    child: Transform.rotate(
                      angle: -0.25,
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 200,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Wassim Food Logo avatar (NOT McDonald's)
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fastfood_rounded,
                              color: Color(0xFF8D4B38),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Wassim Food QR Menu',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${branchProvider.selectedBranch?.name ?? (branches.isNotEmpty ? branches.first.name : "Maarif Branch")} • ${branchProvider.selectedBranch?.city.isNotEmpty == true ? branchProvider.selectedBranch!.city : "Casablanca"}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.88),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Bottom Statistics Chips (Two equal width chips side by side)
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeroChip(
                              icon: Icons.qr_code_2_rounded,
                              label: '${branches.length} Total QR Menus',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildHeroChip(
                              icon: Icons.check_circle_outline_rounded,
                              label: '${branches.length} Active Branches',
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

          const SizedBox(height: 28),

          // Main Section Title
          Text(
            'Branch QR Menus',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          if (branches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No branches available.')),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth;
                int crossAxisCount = (maxWidth / 380).floor();
                if (crossAxisCount < 1) crossAxisCount = 1;

                final double spacing = 16.0;
                final double itemWidth = crossAxisCount == 1
                    ? maxWidth
                    : (maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: List.generate(branches.length, (index) {
                    final branch = branches[index];
                    final qrLink = branch.qrUrl.isNotEmpty
                        ? branch.qrUrl
                        : 'https://wassimfood.com/menu/${branch.slug}';
                    final city = branch.city.isNotEmpty ? branch.city : 'Casablanca';

                    return SizedBox(
                      width: itemWidth,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Row: Branch Icon, Name, City, Status
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        branch.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$city • Morocco',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), height: 1),
                            const SizedBox(height: 16),

                            // Middle Row: Delivery time & Fee in DH
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade500),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Time: ${branch.deliveryTime.isNotEmpty ? branch.deliveryTime : "20-30 min"}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.delivery_dining_outlined, size: 16, color: Colors.grey.shade500),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Fee: ${CurrencyFormatter.formatDH(branch.deliveryFee)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Bottom Row: Primary Show QR + Secondary Icon Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showPrintQRDialog(context, branch, qrLink),
                                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                    label: const Text(
                                      'Show QR',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildRoundedIconButton(
                                  icon: Icons.copy_rounded,
                                  tooltip: 'Copy Link',
                                  isDark: isDark,
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: qrLink));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Menu URL copied to clipboard'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildRoundedIconButton(
                                  icon: Icons.download_rounded,
                                  tooltip: 'Download QR',
                                  isDark: isDark,
                                  onPressed: () => _downloadQR(context, branch, qrLink),
                                ),
                                const SizedBox(width: 6),
                                _buildRoundedIconButton(
                                  icon: Icons.print_rounded,
                                  tooltip: 'Print QR',
                                  isDark: isDark,
                                  onPressed: () => _printQR(context, branch, qrLink),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeroChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedIconButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF1F5F9),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, size: 18, color: isDark ? Colors.white70 : const Color(0xFF475569)),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _downloadQR(BuildContext context, Branch branch, String link) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: link,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      final qrCode = qrValidationResult.qrCode;
      if (qrCode == null) return;

      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        emptyColor: const Color(0x00FFFFFF),
        gapless: true,
      );

      final picData = await painter.toImageData(2048, format: ui.ImageByteFormat.png);
      if (picData != null) {
        final buffer = picData.buffer.asUint8List();
        await Share.shareXFiles(
          [XFile.fromData(buffer, mimeType: 'image/png', name: '${branch.slug}_qr.png')],
          text: 'QR Menu for ${branch.name}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating QR: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printQR(BuildContext context, Branch branch, String link) async {
    try {
      final doc = pw.Document();

      final qrValidationResult = QrValidator.validate(
        data: link,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      final painter = QrPainter.withQr(
        qr: qrValidationResult.qrCode!,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );
      final picData = await painter.toImageData(1024, format: ui.ImageByteFormat.png);
      final img = pw.MemoryImage(picData!.buffer.asUint8List());

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Wassim Food',
                    style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    branch.name,
                    style: pw.TextStyle(fontSize: 20, color: PdfColors.deepOrange),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    branch.address,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 32),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(16),
                      border: pw.Border.all(color: PdfColors.grey300, width: 2),
                    ),
                    child: pw.Image(img, width: 200, height: 200),
                  ),
                  pw.SizedBox(height: 32),
                  pw.Text(
                    'SCAN ME',
                    style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, letterSpacing: 2),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'To view our full menu and order directly from your phone.',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: '${branch.slug}_qr_menu',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing QR: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPrintQRDialog(BuildContext context, Branch branch, String link) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminQrDetailsScreen(branch: branch, qrLink: link),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Tab 8: Analytics View
  // -------------------------------------------------------------------
  Widget _buildAnalyticsTab(
    BuildContext context,
    AdminProvider adminProvider,
    BranchProvider branchProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Calculate branch performance metrics
    final Map<String, double> branchRevenue = {};
    final Map<String, int> branchOrders = {};
    for (var order in adminProvider.orders) {
      final name = order.branch.name;
      branchRevenue[name] = (branchRevenue[name] ?? 0) + order.totalAmount;
      branchOrders[name] = (branchOrders[name] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics & Reports',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Business statistics, branch performance metrics, and sales analysis.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 24),

        // Branch Breakdown
        Text(
          'Performance by Branch',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (branchRevenue.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No sales statistics to analyze.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: branchRevenue.length,
            itemBuilder: (context, index) {
              final branchName = branchRevenue.keys.elementAt(index);
              final revenue = branchRevenue[branchName]!;
              final orderCount = branchOrders[branchName]!;
              final averageTicket = orderCount > 0 ? revenue / orderCount : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bar_chart, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branchName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$orderCount Orders  |  Avg. Ticket: ${CurrencyFormatter.formatDH(averageTicket)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatDH(revenue),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
