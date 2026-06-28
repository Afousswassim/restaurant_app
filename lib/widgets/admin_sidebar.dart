import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final String activeItem;
  final Function(String) onItemSelected;
  final VoidCallback onLogout;

  const AdminSidebar({
    Key? key,
    required this.activeItem,
    required this.onItemSelected,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard},
      {'title': 'Orders', 'icon': Icons.shopping_bag_outlined, 'activeIcon': Icons.shopping_bag},
      {'title': 'Products', 'icon': Icons.restaurant_menu_outlined, 'activeIcon': Icons.restaurant_menu},
      {'title': 'Categories', 'icon': Icons.category_outlined, 'activeIcon': Icons.category},
      {'title': 'Customers', 'icon': Icons.people_outline_rounded, 'activeIcon': Icons.people_rounded},
      {'title': 'Offers', 'icon': Icons.local_offer_outlined, 'activeIcon': Icons.local_offer},
      {'title': 'QR Menu', 'icon': Icons.qr_code_scanner_outlined, 'activeIcon': Icons.qr_code_scanner},
      {'title': 'Analytics', 'icon': Icons.analytics_outlined, 'activeIcon': Icons.analytics},
    ];

    return Container(
      width: 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo Area
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Wassim Food',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E1E26),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Modern Restaurant Admin',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),

          // Menu List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final title = item['title'] as String;
                final isActive = activeItem.toLowerCase() == title.toLowerCase();
                final icon = isActive ? (item['activeIcon'] as IconData) : (item['icon'] as IconData);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryColor.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        if (isActive)
                          Positioned(
                            left: 0,
                            top: 12,
                            bottom: 12,
                            child: Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          leading: Icon(
                            icon,
                            color: isActive
                                ? primaryColor
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            size: 20,
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              color: isActive
                                  ? primaryColor
                                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () => onItemSelected(title),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer info / Promotion Banner card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Mini premium promotional banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fast support line?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reach out to tech support anytime.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 32),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Contact Help',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Logout Button
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
