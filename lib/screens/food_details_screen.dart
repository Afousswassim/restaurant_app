import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/helpers.dart';

class FoodDetailsScreen extends StatefulWidget {
  final MenuItem menuItem;

  const FoodDetailsScreen({
    Key? key,
    required this.menuItem,
  }) : super(key: key);

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  int _quantity = 1;
  final List<ExtraOption> _selectedExtras = [];

  void _toggleExtra(ExtraOption extra) {
    setState(() {
      if (_selectedExtras.contains(extra)) {
        _selectedExtras.remove(extra);
      } else {
        _selectedExtras.add(extra);
      }
    });
  }

  double get _unitPrice {
    double extraCost = _selectedExtras.fold(0.0, (sum, extra) => sum + extra.price);
    return widget.menuItem.price + extraCost;
  }

  double get _totalPrice => _unitPrice * _quantity;

  void _onAddToCart() async {
    final branchProvider = context.read<BranchProvider>();
    final cartProvider = context.read<CartProvider>();
    final selectedBranch = branchProvider.selectedBranch;

    if (selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a branch first.')),
      );
      return;
    }

    try {
      await cartProvider.addToCart(
        widget.menuItem,
        selectedBranch,
        _quantity,
        _selectedExtras,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.menuItem.name} added to cart!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuItem.name),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food Image
                      Image.network(
                        widget.menuItem.imageUrl.isNotEmpty
                            ? widget.menuItem.imageUrl
                            : 'https://images.unsplash.com/photo-1495195134139-0d4517b28b9f?w=600&h=300&fit=crop',
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.deepOrange),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name & Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.menuItem.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  CurrencyFormatter.formatDH(widget.menuItem.price),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Description
                            Text(
                              widget.menuItem.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Extras section
                            if (widget.menuItem.extras.isNotEmpty) ...[
                              const Text(
                                'Customize Your Order',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: widget.menuItem.extras.length,
                                itemBuilder: (context, index) {
                                  final extra = widget.menuItem.extras[index];
                                  final isSelected = _selectedExtras.contains(extra);

                                  return CheckboxListTile(
                                    title: Text(extra.name),
                                    subtitle: Text('+${CurrencyFormatter.formatDH(extra.price)}'),
                                    value: isSelected,
                                    onChanged: (_) => _toggleExtra(extra),
                                    activeColor: Colors.deepOrange,
                                    contentPadding: EdgeInsets.zero,
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Quantity Selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Quantity',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _quantity > 1
                                          ? () => setState(() => _quantity--)
                                          : null,
                                      icon: const Icon(Icons.remove_circle_outline, size: 28),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        '$_quantity',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() => _quantity++),
                                      icon: const Icon(Icons.add_circle_outline, size: 28),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Total and Add Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Price',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatDH(_totalPrice),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
