import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/branch_provider.dart';
import '../providers/menu_provider.dart';
import '../models/menu_item.dart';

class PaperFlyerMenu extends StatefulWidget {
  final String branchName;

  const PaperFlyerMenu({super.key, required this.branchName});

  static Future<void> show(BuildContext context, String branchName) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.95,
        child: PaperFlyerMenu(branchName: branchName),
      ),
    );
  }

  @override
  State<PaperFlyerMenu> createState() => _PaperFlyerMenuState();
}

class _PaperFlyerMenuState extends State<PaperFlyerMenu> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider = context.read<MenuProvider>();
      final branchProvider = context.read<BranchProvider>();
      final selectedBranch = branchProvider.selectedBranch;
      if (selectedBranch != null && menuProvider.rawMenuItems.isEmpty && !menuProvider.isLoading) {
        menuProvider.loadMenu(selectedBranch.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final branchProvider = context.watch<BranchProvider>();
    final selectedBranch = branchProvider.selectedBranch;
    final branchName = selectedBranch?.name ?? widget.branchName;

    // Group raw menu items by category (normalized map)
    final Map<String, List<MenuItem>> groupedItems = {};
    for (var item in menuProvider.rawMenuItems) {
      final cat = item.category.toLowerCase().trim();
      String displayCat = item.category;
      if (cat.contains('burger')) {
        displayCat = 'Burger';
      } else if (cat.contains('pizza')) {
        displayCat = 'Pizza';
      } else if (cat.contains('crepe')) {
        displayCat = 'Crepe';
      } else if (cat.contains('dessert') || cat.contains('sweet')) {
        displayCat = 'Dessert';
      } else if (cat.contains('drink') || cat.contains('beverage')) {
        displayCat = 'Drinks';
      }

      groupedItems.putIfAbsent(displayCat, () => []).add(item);
    }

    // Sort categories based on requested order, placing others at the end
    final categoryOrder = ['Burger', 'Pizza', 'Crepe', 'Dessert', 'Drinks'];
    final sortedCategories = groupedItems.keys.toList();
    sortedCategories.sort((a, b) {
      int idxA = categoryOrder.indexWhere((c) => a.toLowerCase().contains(c.toLowerCase()));
      int idxB = categoryOrder.indexWhere((c) => b.toLowerCase().contains(c.toLowerCase()));
      if (idxA == -1) idxA = 999;
      if (idxB == -1) idxB = 999;
      return idxA.compareTo(idxB);
    });

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFDF9F2), // Cream paper background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(branchName),
                        if (menuProvider.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8D6E63)),
                              ),
                            ),
                          )
                        else if (menuProvider.rawMenuItems.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child: Text(
                                'No products available for this branch.',
                                style: TextStyle(
                                  color: Color(0xFF8D6E63),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else
                          for (final category in sortedCategories) ...[
                            _buildCategoryHeader(category),
                            for (final item in groupedItems[category]!)
                              _buildProductRow(context, item, selectedBranch),
                            const SizedBox(height: 24),
                          ],
                      ],
                    ),
                  ),
                ),
                _buildStickyFooter(context),
              ],
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x228D6E63), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String branchName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Wassim Food Menu',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF3E2723),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Official Premium Menu - Delivery & Pickup',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8D6E63),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7EFE0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x3B8D6E63), width: 1),
          ),
          child: Text(
            'CURRENT BRANCH: ${branchName.toUpperCase()}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
              letterSpacing: 0.8,
          ),
        ),
      ),
      const SizedBox(height: 20),
      const _DottedLine(color: Color(0x7F8D6E63)),
      const SizedBox(height: 16),
    ],
  );
}

  Widget _buildCategoryHeader(String categoryName) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          height: 1.0,
          color: const Color(0x268D6E63),
        ),
        const SizedBox(height: 8),
        Text(
          '✦  ${categoryName.toUpperCase()}  ✦',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8D6E63),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1.0,
          color: const Color(0x268D6E63),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProductRow(BuildContext context, MenuItem item, dynamic selectedBranch) {
    final cartProvider = context.read<CartProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E2723),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _DottedLine(),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.price.toInt()} DH',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  if (selectedBranch != null) {
                    await cartProvider.addToCart(item, selectedBranch, 1, []);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} added to cart!'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF8D6E63),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x0F8D6E63),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x338D6E63), width: 1),
                  ),
                  child: const Text(
                    '+ Order',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8D6E63),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description,
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF5EBD6),
        border: Border(
          top: BorderSide(color: Color(0x228D6E63), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '✦ Smart Interactive Printable Menu',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8D6E63),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF795548),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Back to Store',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLine extends StatelessWidget {
  final Color color;
  const _DottedLine({this.color = const Color(0x3B8D6E63)});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width <= 0) return const SizedBox.shrink();
        const dotRadius = 1.0;
        const spacing = 4.0;
        final count = (width / (dotRadius * 2 + spacing)).floor();
        if (count <= 0) return const SizedBox.shrink();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dotRadius * 2,
              height: dotRadius * 2,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
