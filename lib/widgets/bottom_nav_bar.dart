import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/client_provider.dart';
import '../utils/helpers.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onHomeTap;
  final VoidCallback? onMenuTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.onHomeTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);

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
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8D4B38).withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                  blurRadius: 16,
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
                      activeIcon: Icons.home_rounded,
                      inactiveIcon: Icons.home_outlined,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                    ),
                    _buildNavItem(
                      context: context,
                      index: 1,
                      activeIcon: Icons.restaurant_menu_rounded,
                      inactiveIcon: Icons.restaurant_menu_outlined,
                      label: 'Menu',
                      isSelected: currentIndex == 1,
                    ),
                    _buildNavItem(
                      context: context,
                      index: 2,
                      activeIcon: Icons.shopping_bag_rounded,
                      inactiveIcon: Icons.shopping_bag_outlined,
                      label: 'My Cart',
                      isSelected: currentIndex == 2,
                      showBadge: true,
                    ),
                    _buildNavItem(
                      context: context,
                      index: 3,
                      activeIcon: Icons.receipt_long_rounded,
                      inactiveIcon: Icons.receipt_long_outlined,
                      label: 'Orders',
                      isSelected: currentIndex == 3,
                    ),
                    Consumer<ClientProvider>(
                      builder: (context, clientProvider, _) {
                        final label = clientProvider.isAuthenticated
                            ? (clientProvider.currentClient?.fullName.split(' ').first ?? 'Profile')
                            : 'Profile';
                        return _buildNavItem(
                          context: context,
                          index: 4,
                          activeIcon: Icons.person_rounded,
                          inactiveIcon: Icons.person_outline_rounded,
                          label: label,
                          isSelected: currentIndex == 4,
                        );
                      },
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
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required bool isSelected,
    bool showBadge = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const activeColor = Color(0xFF8D4B38);
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context, index),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF8D4B38).withValues(alpha: 0.18) : const Color(0xFFF9EFEA))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 22,
                  ),
                  if (showBadge)
                    Consumer<CartProvider>(
                      builder: (context, cart, _) {
                        if (cart.totalQuantity == 0) return const SizedBox.shrink();
                        return Positioned(
                          right: -8,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                                  fontSize: 10,
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
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
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
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        break;
      case 1:
        Navigator.of(context).pushNamedAndRemoveUntil('/menu', (route) => false);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/cart');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/orders');
        break;
      case 4:
        final clientProvider = context.read<ClientProvider>();
        if (clientProvider.isAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/client-profile');
        } else {
          Navigator.of(context).pushReplacementNamed('/client-login');
        }
        break;
    }
  }
}
