import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math' as math;
import '../providers/client_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/branch_provider.dart';
import '../providers/menu_provider.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../models/branch.dart';
import '../utils/helpers.dart';
import '../config/app_config.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_order_card.dart';
import '../widgets/admin_chart_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const routeName = '/admin-dashboard';

  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _currentTab = 'Dashboard';
  String _searchQuery = '';
  String? _updatingOrderId;
  String _selectedOrderStatusFilter = 'all';

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchOrders();
      context.read<BranchProvider>().loadBranches();
      context.read<MenuProvider>().loadMenu(null);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
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
      // Close drawer on mobile if open
      if (Navigator.of(context).canPop() && !isDesktop) {
        Navigator.of(context).pop();
      }
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121218) : const Color(0xFFF7F8FA),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            child: _buildBody(context, adminProvider, menuProvider, branchProvider),
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
  Widget _buildTopBar(BuildContext context, AdminProvider adminProvider, bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final adminName = adminProvider.adminInfo?['fullName'] ?? adminProvider.adminInfo?['name'] ?? 'Samantha';

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
                color: isDark ? const Color(0xFF121218) : const Color(0xFFF7F8FA),
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Hello, $adminName',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E1E26),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
        return _buildCategoriesTab(context, menuProvider);
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
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1200;
    
    // Aggregate stats
    final totalProducts = menuProvider.rawMenuItems.length;
    final totalCustomers = adminProvider.orders.map((o) => o.phone).toSet().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title banner
        Text(
          'Dashboard Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hi welcome back. Wassim Food operational statistics at a glance.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 24),

        // Statistics Grid
        LayoutBuilder(builder: (context, constraints) {
          int crossCount = 6;
          if (isMobile) {
            crossCount = 2;
          } else if (isTablet) {
            crossCount = 3;
          }
          final cardRatio = isMobile ? 1.3 : 1.45;

          return GridView.count(
            crossAxisCount: crossCount,
            childAspectRatio: cardRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
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
            ],
          );
        }),
        const SizedBox(height: 28),

        // Charts Section
        LayoutBuilder(builder: (context, constraints) {
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
                    child: AdminRevenueBarChart(totalRevenue: adminProvider.totalRevenue),
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
                      child: AdminRevenueBarChart(totalRevenue: adminProvider.totalRevenue),
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
        }),
        const SizedBox(height: 28),

        // Recent Orders Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
            child: Center(
              child: Text('No orders found.'),
            ),
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

  Widget _buildDashboardOrderCard(BuildContext context, Order order, AdminProvider adminProvider) {
    return AdminOrderCard(
      order: order,
      isUpdating: adminProvider.isLoading && _updatingOrderId == order.id,
      onUpdateStatus: (newStatus) async {
        setState(() {
          _updatingOrderId = order.id;
        });
        final success = await adminProvider.updateOrderStatus(order.id, newStatus);
        setState(() {
          _updatingOrderId = null;
        });
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(adminProvider.error ?? 'Failed to update order status'),
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
      if (_selectedOrderStatusFilter != 'all' && o.status != _selectedOrderStatusFilter) {
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
            Column(
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
            children: ['all', 'pending', 'preparing', 'delivering', 'delivered'].map((status) {
              final isSelected = _selectedOrderStatusFilter == status;
              String display = status[0].toUpperCase() + status.substring(1);
              if (status == 'all') display = 'All Orders';

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    display,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
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
                  backgroundColor: isDark ? const Color(0xFF1E1E26) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    ),
                  ),
                ),
              );
            }).toList(),
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
                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
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
    final search = _searchQuery.toLowerCase();
    final items = menuProvider.rawMenuItems.where((item) {
      if (search.isNotEmpty) {
        return item.name.toLowerCase().contains(search) ||
            item.category.toLowerCase().contains(search);
      }
      return true;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Products (${items.length})',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Live listings available to Wassim Food clients.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 20),

        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('No products available.')),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 700 ? 1 : 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final product = items[index];
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    // Image container
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: Container(
                        width: 100,
                        height: double.infinity,
                        color: Colors.grey.shade100,
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.fastfood, color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.fastfood, color: Colors.grey),
                      ),
                    ),
                    // Detail fields
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  CurrencyFormatter.formatDH(product.price),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: product.isAvailable
                                        ? Colors.green.withOpacity(0.08)
                                        : Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    product.isAvailable ? 'In Stock' : 'Out of Stock',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: product.isAvailable ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
  // Tab 4: Categories View
  // -------------------------------------------------------------------
  Widget _buildCategoriesTab(BuildContext context, MenuProvider menuProvider) {
    final Map<String, int> catCounts = {};
    for (var item in menuProvider.rawMenuItems) {
      catCounts[item.category] = (catCounts[item.category] ?? 0) + 1;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Categories (${catCounts.length})',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cataloged groups for easy buyer menus navigation.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 20),

        if (catCounts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('No categories indexed.')),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: catCounts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 700 ? 2 : 4,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final catName = catCounts.keys.elementAt(index);
              final count = catCounts[catName]!;

              return Container(
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.category_rounded, size: 18, color: primaryColor),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count Products',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
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
  // Tab 5: Customers View
  // -------------------------------------------------------------------
  Widget _buildCustomersTab(BuildContext context, AdminProvider adminProvider) {
    // Group unique customers
    final Map<String, _CustomerInfo> customerMap = {};
    for (var order in adminProvider.orders) {
      final phone = order.phone;
      if (!customerMap.containsKey(phone)) {
        customerMap[phone] = _CustomerInfo(
          name: order.customerName,
          phone: phone,
          address: order.address,
          orderCount: 1,
          totalSpent: order.totalAmount,
        );
      } else {
        final existing = customerMap[phone]!;
        customerMap[phone] = _CustomerInfo(
          name: order.customerName.length > existing.name.length ? order.customerName : existing.name,
          phone: phone,
          address: existing.address,
          orderCount: existing.orderCount + 1,
          totalSpent: existing.totalSpent + order.totalAmount,
        );
      }
    }

    final search = _searchQuery.toLowerCase();
    final customers = customerMap.values.where((c) {
      if (search.isNotEmpty) {
        return c.name.toLowerCase().contains(search) || c.phone.contains(search);
      }
      return true;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registered Customers (${customers.length})',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Detailed summary of customer activities and billing information.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 20),

        if (customers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('No customers found.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];

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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.purple.withOpacity(0.08),
                      child: const Icon(Icons.person, color: Colors.purple),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                customer.phone,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.pin_drop, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  customer.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${customer.orderCount} Orders',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.formatDH(customer.totalSpent),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                      ],
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
  // Tab 6: Offers View
  // -------------------------------------------------------------------
  Widget _buildOffersTab(BuildContext context, MenuProvider menuProvider) {
    final offers = menuProvider.rawMenuItems.where((item) => item.hasOffer).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Offers (${offers.length})',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Menu products with active promotional discounts.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 20),

        if (offers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('No active offers found.')),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offers.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 700 ? 1 : 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final product = offers[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 80,
                            height: double.infinity,
                            color: Colors.grey.shade100,
                            child: product.imageUrl.isNotEmpty
                                ? Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.local_offer, color: Colors.grey),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.offerLabel ?? 'SALE',
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                CurrencyFormatter.formatDH(product.effectivePrice),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                CurrencyFormatter.formatDH(product.price),
                                style: TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade400,
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: branches.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 700 ? 1 : 3,
              childAspectRatio: 2.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final branch = branches[index];
              final qrLink = '${AppConfig.webAppBaseUrl}/?branch=${branch.id}';

              return Container(
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
                          child: const Icon(Icons.storefront_rounded, color: Colors.deepOrange),
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
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                branch.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery time: ${branch.deliveryTime}',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                              Text(
                                'Fee: ${CurrencyFormatter.formatDH(branch.deliveryFee)}',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showPrintQRDialog(context, branch, qrLink),
                          icon: const Icon(Icons.qr_code, size: 16),
                          label: const Text('Show QR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showPrintQRDialog(BuildContext context, Branch branch, String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dine-in Menu QR',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              branch.name,
              style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 200,
                gapless: false,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Link: $link',
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connecting to configured local printer...'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$orderCount Orders  |  Avg. Ticket: ${CurrencyFormatter.formatDH(averageTicket)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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

// -------------------------------------------------------------------
// Helper data structures
// -------------------------------------------------------------------
class _CustomerInfo {
  final String name;
  final String phone;
  final String address;
  final int orderCount;
  final double totalSpent;

  _CustomerInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.orderCount,
    required this.totalSpent,
  });
}
