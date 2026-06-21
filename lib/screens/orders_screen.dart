import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/client_provider.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';
import '../widgets/top_actions.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/orders';
  const OrdersScreen({Key? key}) : super(key: key);

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
        setState(() {
          _displayOrders = orders;
          _isLoading = false;
        });
      } else {
        // Guest: filter by local order IDs
        final localOrderIds = prefs.getStringList('local_orders') ?? [];
        if (localOrderIds.isEmpty) {
          setState(() {
            _displayOrders = [];
            _isLoading = false;
          });
          return;
        }

        final allOrders = await ApiService.getAllOrders();
        setState(() {
          _displayOrders = allOrders.where((order) => localOrderIds.contains(order.id)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Track Orders',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
        actions: const [
          TopActions(),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
          ),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadOrders,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child: Text(
                                'Retry',
                                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: colorScheme.primary,
                      child: _displayOrders.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: size.height * 0.2),
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 72,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    'No orders placed yet.',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _displayOrders.length,
                              itemBuilder: (context, index) {
                                final order = _displayOrders[index];
                                return _buildOrderCard(order);
                              },
                            ),
                    ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildOrderCard(Order order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    Color statusColor;
    switch (order.status) {
      case 'pending':
        statusColor = colorScheme.secondary;
        break;
      case 'preparing':
        statusColor = colorScheme.primary;
        break;
      case 'delivering':
      case 'on-way':
        statusColor = colorScheme.tertiary;
        break;
      case 'delivered':
        statusColor = colorScheme.secondaryContainer;
        break;
      default:
        statusColor = colorScheme.onSurfaceVariant;
    }

    final idTruncated = order.id.length > 6 ? order.id.substring(order.id.length - 6).toUpperCase() : order.id.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ORDER ID: #$idTruncated',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.statusDisplay,
                        style: textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: theme.dividerColor),
            Row(
              children: [
                Icon(Icons.storefront, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  order.branch.name,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Address: ${order.address}',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            Divider(height: 24, color: theme.dividerColor),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '${item.quantity}x ',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.name,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatDH(item.totalPrice),
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                )),
            Divider(height: 24, color: theme.dividerColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatDH(order.totalAmount),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
