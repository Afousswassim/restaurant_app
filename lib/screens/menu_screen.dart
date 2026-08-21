import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/branch_provider.dart';
import '../providers/category_provider.dart';
import '../providers/menu_provider.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/category_tabs.dart';
import '../widgets/paper_flyer_menu.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/client_navbar.dart';
import '../widgets/app_drawer.dart';
import '../screens/branch_selection_screen.dart';
import '../screens/food_details_screen.dart';
import '../utils/helpers.dart';

class MenuScreen extends StatefulWidget {
  static const routeName = '/menu';
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchProvider = context.read<BranchProvider>();
      final menuProvider = context.read<MenuProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final selectedBranch = branchProvider.selectedBranch;
      categoryProvider.loadCategories();
      if (selectedBranch != null && menuProvider.rawMenuItems.isEmpty) {
        menuProvider.loadMenu(selectedBranch.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final branchProvider = context.watch<BranchProvider>();
    final selectedBranch = branchProvider.selectedBranch;
    final menuProvider = context.watch<MenuProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);

    final visibleItems = menuProvider.menuItems.where((item) {
      final isActiveCategory = categoryProvider.activeCategories.any(
        (category) => category.name.toLowerCase() == item.category.toLowerCase(),
      );
      if (!isActiveCategory) return false;
      if (menuProvider.selectedCategory.toLowerCase() == 'all') return true;
      return item.category.toLowerCase() == menuProvider.selectedCategory.toLowerCase();
    }).toList();

    if (selectedBranch == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BranchSelectionScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: const ClientNavbar(title: 'Menu'),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 960,
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Selected Branch Info Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Colors.deepOrange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Currently Ordering From',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedBranch.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF2C1810),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const BranchSelectionScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Change',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search Bar & Paper Flyer Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 520;
                      return Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: isNarrow ? constraints.maxWidth : constraints.maxWidth - 160,
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search for burgers, drinks, meals...',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(Icons.search_rounded, color: Colors.deepOrange),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          menuProvider.setSearchTerm('');
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5),
                                ),
                              ),
                              textInputAction: TextInputAction.search,
                              onChanged: (v) => menuProvider.setSearchTerm(v),
                            ),
                          ),
                          SizedBox(
                            width: isNarrow ? constraints.maxWidth : null,
                            child: ElevatedButton.icon(
                              onPressed: () => PaperFlyerMenu.show(context, selectedBranch.name),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.menu_book_rounded, size: 18),
                              label: const Text(
                                'Paper Flyer',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Reusable Category Navigation Bar (Admin Categories)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CategoryTabs(
                    categories: categoryProvider.activeCategories,
                    selectedCategory: menuProvider.selectedCategory,
                    onSelectCategory: (categoryName) {
                      menuProvider.selectCategory(categoryName);
                      _searchController.clear();
                    },
                  ),
                ),
              ),

              // Product Grid / Loading / Error / Empty States
              if (menuProvider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                    ),
                  ),
                )
              else if (menuProvider.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Failed to load menu items'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => menuProvider.loadMenu(selectedBranch.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (visibleItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try searching for another product or select a different category.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double maxWidth = constraints.maxWidth;
                        int crossAxisCount = (maxWidth / 220).ceil();
                        if (crossAxisCount < 1) crossAxisCount = 1;
                        if (maxWidth > 600 && crossAxisCount < 2) crossAxisCount = 2;

                        final double spacing = 14.0;
                        final double itemWidth =
                            (maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: visibleItems.map((item) {
                            return SizedBox(
                              width: itemWidth,
                              child: MenuItemCard(
                                item: item,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FoodDetailsScreen(menuItem: item),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
