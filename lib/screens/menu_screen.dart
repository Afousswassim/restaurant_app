import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/branch_provider.dart';
import '../providers/category_provider.dart';
import '../providers/menu_provider.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/paper_flyer_menu.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_actions.dart';
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
  Widget build(BuildContext context) {
    final branchProvider = context.watch<BranchProvider>();
    final selectedBranch = branchProvider.selectedBranch;
    final menuProvider = context.watch<MenuProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);

    final visibleCategories = <Map<String, String>>[
      {'name': 'All', 'icon': '🔎'},
      ...categoryProvider.activeCategories.map(
        (category) => {
          'name': category.name,
          'icon': category.icon.isNotEmpty ? category.icon : '🍽️',
        },
      ),
    ];

    final visibleItems = menuProvider.menuItems.where((item) {
      final isActiveCategory = categoryProvider.activeCategories.any(
        (category) =>
            category.name.toLowerCase() == item.category.toLowerCase(),
      );
      if (!isActiveCategory) return false;
      if (menuProvider.selectedCategory.toLowerCase() == 'all') return true;
      return item.category.toLowerCase() ==
          menuProvider.selectedCategory.toLowerCase();
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
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const SizedBox.shrink(),
        actions: const [TopActions()],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 900,
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Selected branch card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Currently Ordering From',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  selectedBranch.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Search + Flyer row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 500;
                      return Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: isNarrow ? constraints.maxWidth : constraints.maxWidth - 150,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search for a product...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          menuProvider.setSearchTerm('');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              textInputAction: TextInputAction.search,
                              onChanged: (v) => menuProvider.setSearchTerm(v),
                            ),
                          ),
                          SizedBox(
                            width: isNarrow ? constraints.maxWidth : null,
                            child: ElevatedButton(
                              onPressed: () =>
                                  PaperFlyerMenu.show(context, selectedBranch.name),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.menu_book, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Paper Flyer'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // Categories
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: visibleCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = visibleCategories[index];
                      final name = category['name']!;
                      return CategoryChip(
                        label: '${category['icon']}  $name',
                        isSelected:
                            menuProvider.selectedCategory.toLowerCase() ==
                            name.toLowerCase(),
                        onTap: () {
                          menuProvider.selectCategory(name);
                          _searchController.clear();
                        },
                      );
                    },
                  ),
                ),
              ),
              // Product grid / states
              if (menuProvider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepOrange,
                      ),
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
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text('Failed to load menu items'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              menuProvider.loadMenu(selectedBranch.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double maxWidth = constraints.maxWidth;
                        int crossAxisCount = (maxWidth / 220).ceil();
                        if (crossAxisCount < 1) crossAxisCount = 1;
                        
                        final double spacing = 12.0;
                        final double itemWidth = (maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                        final items = visibleItems;
                        if (items.isEmpty) {
                          return const Center(child: Text('No products found'));
                        }

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: List.generate(items.length, (index) {
                            final item = items[index];
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
                          }),
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
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}
