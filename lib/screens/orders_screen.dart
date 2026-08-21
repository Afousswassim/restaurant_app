import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/client_provider.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';
import '../widgets/client_navbar.dart';
import '../widgets/order_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/orders';
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _displayOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clientProvider = context.read<ClientProvider>();
      final prefs = await SharedPreferences.getInstance();

      if (clientProvider.isAuthenticated && clientProvider.currentClient != null) {
        // Logged in: fetch client specific orders
        final orders = await ApiService.getClientOrders(clientProvider.currentClient!.id);
        if (mounted) {
          setState(() {
            _displayOrders = orders;
            _isLoading = false;
          });
        }
      } else {
        // Guest: filter by local order IDs
        final localOrderIds = prefs.getStringList('local_orders') ?? [];
        if (localOrderIds.isEmpty) {
          if (mounted) {
            setState(() {
              _displayOrders = [];
              _isLoading = false;
            });
          }
          return;
        }

        final allOrders = await ApiService.getAllOrders();
        if (mounted) {
          setState(() {
            _displayOrders = allOrders.where((order) => localOrderIds.contains(order.id)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: const ClientNavbar(title: 'My Orders'),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 680,
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                  ),
                )
              : _error != null
                  ? _buildErrorState(theme, isDark)
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: Colors.deepOrange,
                      child: _displayOrders.isEmpty
                          ? _buildEmptyState(context, isDark)
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                              itemCount: _displayOrders.length,
                              itemBuilder: (context, index) {
                                final order = _displayOrders[index];
                                return OrderCard(
                                  order: order,
                                  onTap: () {},
                                );
                              },
                            ),
                    ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
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
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No orders placed yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When you place an order, it will appear here with live tracking & complete details.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/menu', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.restaurant_menu_rounded),
                  label: const Text(
                    'Explore Menu',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Failed to load orders',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
