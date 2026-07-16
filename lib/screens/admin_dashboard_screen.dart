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

class AdminDashboardScreen extends StatefulWidget {
  static const routeName = '/admin-dashboard';

  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _currentTab = 'Dashboard';
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
      final isInactive = !isActive && !isExpired;

      if (_selectedOfferStatusFilter == 'Active' && !isActive) return false;
      if (_selectedOfferStatusFilter == 'Inactive' && !isInactive) return false;
      if (_selectedOfferStatusFilter == 'Expired' && !isExpired) return false;

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
              title: Text(editingItem == null ? 'Add Product' : 'Edit Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product name',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      decoration: const InputDecoration(labelText: 'Category'),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (DH)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: caloriesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Calories',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: proteinController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Protein',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available'),
                      value: isAvailable,
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
                FilledButton(
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
      setState(() {
        _currentTab = item;
        _searchQuery = '';
        _searchController.clear();
      });
      // Close drawer on mobile if open without popping the admin route stack
      if (!isDesktop) {
        Scaffold.maybeOf(context)?.closeDrawer();
      }
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121218)
          : const Color(0xFFF7F8FA),
      drawer: !isDesktop
          ? Drawer(
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
                _buildTopBar(context, adminProvider, isDesktop),

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
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
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
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF121218)
                    : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(10),
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
                  contentPadding: const EdgeInsets.only(top: 8),
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
        return _buildOffersTab(context, menuProvider);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  const SizedBox(height: 20),
                  const SizedBox(
                    height: 300,
                    child: AdminChartCard(
                      title: 'Popular Products',
                      child: AdminPopularProductsChart(),
                    ),
                  ),
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
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
                    flex: 3,
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
                  const SizedBox(width: 16),
                  const Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 240,
                      child: AdminChartCard(
                        title: 'Popular Products',
                        child: AdminPopularProductsChart(),
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
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Orders',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage and process Wassim Food customer transactions.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Count: ${filteredOrders.length}',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['all', 'pending', 'preparing', 'delivering', 'delivered']
                .map((status) {
                  final isSelected = _selectedOrderStatusFilter == status;
                  String display =
                      status[0].toUpperCase() + status.substring(1);
                  if (status == 'all') display = 'All Orders';

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        display,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedOrderStatusFilter = status;
                        });
                      },
                      selectedColor: primaryColor,
                      checkmarkColor: Colors.white,
                      backgroundColor: isDark
                          ? const Color(0xFF1E1E26)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? primaryColor
                              : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                        ),
                      ),
                    ),
                  );
                })
                .toList(),
          ),
        ),
        const SizedBox(height: 16),

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
  Widget _buildProductsTab(BuildContext context, MenuProvider menuProvider) {
    final items = _filterAdminProducts(menuProvider.rawMenuItems);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final categories = <String>{'All'};
    categories.addAll(
      menuProvider.rawMenuItems
          .map((item) => item.category)
          .where((value) => value.isNotEmpty),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        LayoutBuilder(
          builder: (context, constraints) {
            final double buttonMaxWidth = constraints.maxWidth < 560 ? constraints.maxWidth : 180.0;
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: constraints.maxWidth < 560 ? constraints.maxWidth : constraints.maxWidth - buttonMaxWidth - 16.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu Products (${items.length})',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live listings available to Wassim Food clients.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                  child: FilledButton.icon(
                    onPressed: () => _showProductDialog(context),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Product'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Filters Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'FILTER BY CATEGORY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Categories scrollable chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedProductCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedProductCategory = cat;
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
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Status Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'FILTER BY AVAILABILITY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Status ChoiceChips
        Row(
          children: [
            _buildStatusChip(context, 'All', 'All Products', isDark, primaryColor),
            const SizedBox(width: 8),
            _buildStatusChip(context, 'In Stock', 'In Stock', isDark, primaryColor),
            const SizedBox(width: 8),
            _buildStatusChip(context, 'Out of Stock', 'Out of Stock', isDark, primaryColor),
          ],
        ),
        const SizedBox(height: 24),

        // Product Grid List
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
                    'No products found matching the criteria.',
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
              final double maxWidth = constraints.maxWidth;
              int crossAxisCount = 1;
              if (maxWidth < 600) {
                crossAxisCount = 2;
              } else if (maxWidth < 960) {
                crossAxisCount = 3;
              } else if (maxWidth < 1300) {
                crossAxisCount = 4;
              } else {
                crossAxisCount = 5;
              }

              final double spacing = 16.0;
              final double itemWidth = (maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(items.length, (index) {
                  final product = items[index];
                  return SizedBox(
                    width: itemWidth,
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: isDark ? Colors.grey.shade900 : const Color(0xFFF1F5F9),
                          width: 1.5,
                        ),
                      ),
                      color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Product Image + Status Floating Badge
                          Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 11,
                                child: product.imageUrl.isNotEmpty
                                    ? Image.network(
                                        product.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                                          child: Icon(
                                            Icons.fastfood_outlined,
                                            color: Colors.grey.shade400,
                                            size: 40,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                                        child: Icon(
                                          Icons.fastfood_outlined,
                                          color: Colors.grey.shade400,
                                          size: 40,
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: (product.isAvailable ? Colors.green : Colors.red).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        product.isAvailable ? 'In Stock' : 'Out of Stock',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Product Info
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 14),
                                Divider(
                                  height: 1,
                                  color: isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9),
                                ),
                                const SizedBox(height: 12),

                                // Price & Action Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      CurrencyFormatter.formatDH(product.price),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF1F5F9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            onPressed: () => _showProductDialog(
                                              context,
                                              editingItem: product,
                                            ),
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              size: 15,
                                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                                            ),
                                            tooltip: 'Edit',
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.redAccent.withOpacity(0.12) : const Color(0xFFFFEBEE),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            onPressed: () => _confirmDeleteProduct(context, product),
                                            icon: Icon(
                                              Icons.delete_outline,
                                              size: 15,
                                              color: isDark ? Colors.redAccent : Colors.red,
                                            ),
                                            tooltip: 'Delete',
                                            padding: EdgeInsets.zero,
                                          ),
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
                  );
                }),
              );
            },
          ),
      ],
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
  Widget _buildOffersTab(BuildContext context, MenuProvider menuProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
    final totalInactive = allOffers.length - totalActive - totalExpired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Offers Management',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage product offers attached to existing menu items.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showOfferDialog(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Offer'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildOfferStatusChip(
              'All',
              allOffers.length,
              _selectedOfferStatusFilter == 'All',
              () {
                setState(() => _selectedOfferStatusFilter = 'All');
              },
            ),
            _buildOfferStatusChip(
              'Active',
              totalActive,
              _selectedOfferStatusFilter == 'Active',
              () {
                setState(() => _selectedOfferStatusFilter = 'Active');
              },
            ),
            _buildOfferStatusChip(
              'Inactive',
              totalInactive,
              _selectedOfferStatusFilter == 'Inactive',
              () {
                setState(() => _selectedOfferStatusFilter = 'Inactive');
              },
            ),
            _buildOfferStatusChip(
              'Expired',
              totalExpired,
              _selectedOfferStatusFilter == 'Expired',
              () {
                setState(() => _selectedOfferStatusFilter = 'Expired');
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            if (isMobile) {
              return Column(
                children: [
                  TextField(
                    controller: _offerSearchController,
                    decoration: InputDecoration(
                      hintText:
                          'Search offers by product, category, title, or label',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _offerSearchQuery = value.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedOfferCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      isDense: true,
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedOfferCategory = value;
                        });
                      }
                    },
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _offerSearchController,
                    decoration: InputDecoration(
                      hintText:
                          'Search offers by product, category, title, or label',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _offerSearchQuery = value.trim();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedOfferCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      isDense: true,
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedOfferCategory = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        if (menuProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              ),
            ),
          )
        else if (offers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('No offers found.')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final active = _isOfferCurrentlyActive(offer);
              final expired = _isOfferExpired(offer);
              final statusLabel = expired
                  ? 'Expired'
                  : active
                  ? 'Active'
                  : 'Inactive';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 110,
                        height: 110,
                        color: Colors.grey.shade100,
                        child: offer.imageUrl.isNotEmpty
                            ? Image.network(offer.imageUrl, fit: BoxFit.cover)
                            : const Icon(
                                Icons.fastfood,
                                color: Colors.grey,
                                size: 42,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  offer.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showOfferDialog(
                                  context,
                                  editingOffer: offer,
                                ),
                                child: const Icon(Icons.edit, size: 20),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () =>
                                    _confirmDeleteOffer(context, offer),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            offer.category,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            offer.offerTitle ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            offer.offerDescription ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (offer.oldPrice != null)
                                Text(
                                  CurrencyFormatter.formatDH(offer.oldPrice!),
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              if (offer.oldPrice != null)
                                const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.formatDH(
                                  offer.offerPrice ?? offer.effectivePrice,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.green.withOpacity(0.12)
                                      : Colors.grey.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: active
                                        ? Colors.green.shade700
                                        : Colors.grey.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Start ${_formatSimpleDate(offer.offerStartDate)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                'Expires ${_formatSimpleDate(offer.offerExpiresAt)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    offer.offerLabel ?? 'OFFER',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch.adaptive(
                                      value:
                                          _pendingOfferToggle[offer.id] ??
                                          offer.isOfferActive,
                                      onChanged: (value) =>
                                          _toggleOfferActive(context, offer, value),
                                    ),
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
              );
            },
          ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Tab 7: QR Menu View
  // -------------------------------------------------------------------
  Widget _buildQRMenuTab(BuildContext context, BranchProvider branchProvider) {
    final branches = branchProvider.branches;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR Menus Manager',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Generate and print dine-in QR menus for Wassim Food branches.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 24),

        if (branches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('No branches available.')),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              int crossAxisCount = (maxWidth / 400).ceil();
              if (crossAxisCount < 1) crossAxisCount = 1;
              
              final double spacing = 16.0;
              final double itemWidth = (maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(branches.length, (index) {
                  final branch = branches[index];
                  // Use the new branch.qrUrl from backend, fallback to manual if empty
                  final qrLink = branch.qrUrl.isNotEmpty 
                      ? branch.qrUrl 
                      : 'https://wassimfood.com/menu/${branch.slug}';

                  return SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      branch.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      branch.address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time: ${branch.deliveryTime}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Fee: ${CurrencyFormatter.formatDH(branch.deliveryFee)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: qrLink));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Menu URL copied to clipboard'), backgroundColor: Colors.green),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: 'Copy Link',
                                color: Colors.grey.shade600,
                              ),
                              IconButton(
                                onPressed: () => _printQR(context, branch, qrLink),
                                icon: const Icon(Icons.print_rounded, size: 18),
                                tooltip: 'Print QR',
                                color: Colors.grey.shade600,
                              ),
                              IconButton(
                                onPressed: () => _downloadQR(context, branch, qrLink),
                                icon: const Icon(Icons.download_rounded, size: 18),
                                tooltip: 'Download PNG',
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showPrintQRDialog(context, branch, qrLink),
                                icon: const Icon(Icons.qr_code, size: 16),
                                label: const Text('Show QR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
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
        emptyColor: const Color(0x00FFFFFF), // Transparent background as requested
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating QR: $e'), backgroundColor: Colors.red));
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
        emptyColor: const Color(0xFFFFFFFF), // White background for print
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error printing QR: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showPrintQRDialog(BuildContext context, Branch branch, String link) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 450,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E26) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Restaurant Logo/Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant_menu_rounded, color: Colors.deepOrange, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Wassim Food',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      branch.name,
                      style: const TextStyle(fontSize: 18, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      branch.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Large QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: QrImageView(
                        data: link,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        gapless: false,
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size(40, 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        link,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: link));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('URL Copied!'), backgroundColor: Colors.green),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _downloadQR(context, branch, link),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () => _printQR(context, branch, link),
                            icon: const Icon(Icons.print_rounded, size: 18),
                            label: const Text('Print A5 Menu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
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
