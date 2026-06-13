import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/admin_provider.dart';
import '../screens/home_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/admin_login_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../utils/helpers.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onHomeTap;
  final VoidCallback? onMenuTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    this.onHomeTap,
    this.onMenuTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 600,
            ),
            margin: EdgeInsets.only(
              left: isMobile ? 16 : 0,
              right: isMobile ? 16 : 0,
              bottom: isMobile ? 16 : 10,
              top: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      context: context,
                      index: 0,
                      icon: Icons.home,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                      primaryColor: primaryColor,
                    ),
                    _buildNavItem(
                      context: context,
                      index: 1,
                      icon: Icons.restaurant_menu,
                      label: 'Menu',
                      isSelected: currentIndex == 1,
                      primaryColor: primaryColor,
                    ),
                    _buildNavItem(
                      context: context,
                      index: 2,
                      icon: Icons.shopping_cart,
                      label: 'My Cart',
                      isSelected: currentIndex == 2,
                      primaryColor: primaryColor,
                      showBadge: true,
                    ),
                    _buildNavItem(
                      context: context,
                      index: 3,
                      icon: Icons.receipt_long,
                      label: 'Orders',
                      isSelected: currentIndex == 3,
                      primaryColor: primaryColor,
                    ),
                    _buildNavItem(
                      context: context,
                      index: 4,
                      icon: Icons.person,
                      label: 'Login',
                      isSelected: currentIndex == 4,
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color primaryColor,
    bool showBadge = false,
  }) {
    return InkWell(
      onTap: () => _onTap(context, index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? primaryColor : Colors.grey.shade500,
                  size: 24,
                ),
                if (showBadge)
                  Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      if (cart.totalQuantity == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              '${cart.totalQuantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) {
      if (index == 0 && onHomeTap != null) {
        onHomeTap!();
      } else if (index == 1 && onMenuTap != null) {
        onMenuTap!();
      }
      return;
    }

    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen(scrollToMenu: true)),
          (route) => false,
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
        break;
      case 3:
        _showOrdersDialog(context);
        break;
      case 4:
        final adminProvider = context.read<AdminProvider>();
        if (adminProvider.isAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
          );
        }
        break;
    }
  }

  void _showOrdersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Order Status Tracking'),
        content: const Text(
          'You can track your order status after checking out. '
          'If you are an administrator and wish to manage customer orders, please log in via the Admin Portal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final adminProvider = context.read<AdminProvider>();
              if (adminProvider.isAuthenticated) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Admin Portal'),
          ),
        ],
      ),
    );
  }
}
