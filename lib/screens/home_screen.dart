import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/branch_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/paper_flyer_card.dart';
import '../widgets/paper_flyer_menu.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/popular_item_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/client_navbar.dart';
import '../widgets/top_actions.dart';
import '../widgets/app_drawer.dart';
import '../widgets/faq_section.dart';
import '../widgets/app_footer.dart';
import '../screens/branch_selection_screen.dart';
import '../screens/food_details_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/cart_screen.dart';
import '../utils/helpers.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  final bool scrollToMenu;

  const HomeScreen({super.key, this.scrollToMenu = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _currentBottomNavIndex = 0;
  bool _hasNavigatedToMenu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final branchProvider = context.read<BranchProvider>();
    final menuProvider = context.read<MenuProvider>();
    final selectedBranch = branchProvider.selectedBranch;

    if (selectedBranch != null && menuProvider.rawMenuItems.isEmpty && !menuProvider.isLoading) {
      menuProvider.loadMenu(selectedBranch.id);
    }

    if (widget.scrollToMenu && !_hasNavigatedToMenu) {
      _hasNavigatedToMenu = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openMenu();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openMenu() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
    );
  }

  void _openPaperFlyer(String branchName) {
    PaperFlyerMenu.show(context, branchName);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);
    final branchProvider = context.watch<BranchProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final selectedBranch = branchProvider.selectedBranch;
    final previewItems = menuProvider.rawMenuItems.take(4).toList();

    if (selectedBranch == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BranchSelectionScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const ClientNavbar(),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 900),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for your favorite meal...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _openMenu(),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: HomeHeroBanner(onExplore: _openMenu)),
              SliverToBoxAdapter(child: PaperFlyerCard(onPreview: () => _openPaperFlyer(selectedBranch.name))),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Popular Picks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: _openMenu, child: const Text('View All')),
                    ],
                  ),
                ),
              ),
              if (previewItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('Loading curated menu preview...', style: TextStyle(color: Colors.black54)),
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 130,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = constraints.maxWidth < 360 ? constraints.maxWidth * 0.9 : 330.0;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: previewItems.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = previewItems[index];
                            return SizedBox(
                              width: itemWidth,
                              child: PopularItemCard(
                                item: item,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => FoodDetailsScreen(menuItem: item)),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(child: FaqSection()),
              const SliverToBoxAdapter(child: AppFooter()),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.totalQuantity == 0) return const SizedBox.shrink();

          return Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed(CartScreen.routeName);
              },
              backgroundColor: Colors.deepOrange,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'View Cart (${cart.totalQuantity} items)',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      CurrencyFormatter.formatDH(cart.subtotal),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          );
        },

      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onHomeTap: () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            );
          }
          setState(() {
            _currentBottomNavIndex = 0;
          });
        },
        onMenuTap: _openMenu,
      ),
    );
  }
}
