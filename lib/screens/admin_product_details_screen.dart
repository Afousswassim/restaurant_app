import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../utils/helpers.dart';

class AdminProductDetailsScreen extends StatefulWidget {
  final MenuItem product;
  final Function(MenuItem) onEdit;
  final Function(MenuItem) onDelete;
  final Function(MenuItem, bool) onToggleAvailability;

  const AdminProductDetailsScreen({
    Key? key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  }) : super(key: key);

  @override
  State<AdminProductDetailsScreen> createState() => _AdminProductDetailsScreenState();
}

class _AdminProductDetailsScreenState extends State<AdminProductDetailsScreen> {
  String _selectedMealSize = 'Medium Meal';
  final Set<String> _selectedExtras = {'Extra Cheese'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final product = widget.product;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: colorScheme.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Product Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              product.isAvailable ? Icons.check_circle_rounded : Icons.do_not_disturb_on_rounded,
              color: product.isAvailable ? Colors.green : Colors.red,
            ),
            tooltip: product.isAvailable ? 'In Stock' : 'Out of Stock',
            onPressed: () => widget.onToggleAvailability(product, !product.isAvailable),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface),
            onSelected: (val) {
              if (val == 'edit') {
                widget.onEdit(product);
              } else if (val == 'delete') {
                widget.onDelete(product);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Product'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Product', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        shape: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Product Card (Reference Layout: Image left + Title/Description/Price right)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.onSurface.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rounded Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: colorScheme.primary.withOpacity(0.1),
                                        child: Icon(Icons.fastfood, size: 40, color: colorScheme.primary),
                                      ),
                                    )
                                  : Container(
                                      color: colorScheme.primary.withOpacity(0.1),
                                      child: Icon(Icons.fastfood, size: 40, color: colorScheme.primary),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  product.description.isNotEmpty
                                      ? product.description
                                      : 'Our signature loaded product crafted with fresh Wassim Food ingredients.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    height: 1.3,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      CurrencyFormatter.formatDH(product.effectivePrice),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    if (product.hasOffer && product.oldPrice != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        CurrencyFormatter.formatDH(product.oldPrice!),
                                        style: TextStyle(
                                          fontSize: 14,
                                          decoration: TextDecoration.lineThrough,
                                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Meal Size Section (Reference Layout)
                    _buildSectionHeader(context, 'Meal Size'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSizeCard(context, 'Medium Meal', null),
                        const SizedBox(width: 10),
                        _buildSizeCard(context, 'Large Meal', '+20.00 DH'),
                        const SizedBox(width: 10),
                        _buildSizeCard(context, 'Burger Only', '+40.00 DH'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Extras Section (Reference Layout)
                    _buildSectionHeader(context, 'Extras'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildExtraCard(context, 'Extra Cheese', '10.00 DH'),
                        _buildExtraCard(context, 'Extra Patty Chicken', '20.00 DH'),
                        _buildExtraCard(context, 'Spicy Sauce', '5.00 DH'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Addons Section (Reference Layout with mini square thumbnails)
                    _buildSectionHeader(context, 'Addons'),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildAddonCard(
                            context,
                            title: 'Coca-Cola (Cane)',
                            price: '10.00 DH',
                            icon: Icons.local_drink_rounded,
                            iconColor: Colors.red,
                          ),
                          const SizedBox(width: 12),
                          _buildAddonCard(
                            context,
                            title: 'Vanilla Pastry',
                            price: '15.00 DH',
                            icon: Icons.cake_rounded,
                            iconColor: Colors.pink,
                          ),
                          const SizedBox(width: 12),
                          _buildAddonCard(
                            context,
                            title: 'French Fries',
                            price: '12.00 DH',
                            icon: Icons.fastfood_rounded,
                            iconColor: Colors.amber.shade700,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Product Specifications Section
                    _buildSectionHeader(context, 'Product Info & Metrics'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          _buildMetricRow(context, 'Category', product.category),
                          const Divider(height: 20),
                          _buildMetricRow(context, 'Status', product.isAvailable ? 'In Stock' : 'Out of Stock'),
                          const Divider(height: 20),
                          _buildMetricRow(context, 'Customer Rating', '★ ${product.rating.toStringAsFixed(1)} (224 ratings)'),
                          if (product.calories > 0) ...[
                            const Divider(height: 20),
                            _buildMetricRow(context, 'Calories', '${product.calories} kcal'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Persistent Bottom Bar (Reference Layout: Prominent primary orange Edit Item button)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => widget.onDelete(product),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.12),
                      foregroundColor: Colors.red,
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    tooltip: 'Delete Product',
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onEdit(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        label: const Text(
                          'Edit Item',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSizeCard(BuildContext context, String title, String? extraPrice) {
    final theme = Theme.of(context);
    final isSelected = _selectedMealSize == title;
    final primaryColor = theme.colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMealSize = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.08) : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : theme.dividerColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? primaryColor : theme.colorScheme.onSurface,
                ),
              ),
              if (extraPrice != null) ...[
                const SizedBox(height: 4),
                Text(
                  extraPrice,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? primaryColor : Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtraCard(BuildContext context, String title, String price) {
    final theme = Theme.of(context);
    final isSelected = _selectedExtras.contains(title);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedExtras.remove(title);
          } else {
            _selectedExtras.add(title);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.08) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : theme.dividerColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryColor : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '+$price',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? primaryColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonCard(
    BuildContext context, {
    required String title,
    required String price,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '+$price',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.info_outline_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
