import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/branch_provider.dart';

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

  String _getInitials(String fullName) {
    final words = fullName.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return fullName.isEmpty ? 'AD' : fullName.substring(0, min(2, fullName.length)).toUpperCase();
  }

  void _closeDrawer(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    scaffold?.closeDrawer();
  }

  void _showContactDialog(BuildContext context) {
    _closeDrawer(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Contact Wassim Food Support', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ListTile(
                leading: Icon(Icons.chat, color: Colors.green),
                title: Text('WhatsApp Support'),
                subtitle: Text('+212 600 123 456'),
              ),
              SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.deepOrange),
                title: Text('Direct Helpline'),
                subtitle: Text('+212 522 999 528'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = size.width >= 1024;

    final adminProvider = context.watch<AdminProvider>();
    final branchProvider = context.watch<BranchProvider>();

    final adminName = adminProvider.adminInfo?['fullName'] ??
        adminProvider.adminInfo?['name'] ??
        'Admin User';
    final adminRole = adminProvider.adminInfo?['role'] ?? 'Store Manager';
    final currentBranchName = branchProvider.selectedBranch?.name ?? 'ALL BRANCHES';
    final initials = _getInitials(adminName);

    final activeBg = isDark ? const Color(0x26E65100) : const Color(0xFFFFEBE5);
    final activeTextColor = isDark ? const Color(0xFFFF8A65) : const Color(0xFFD84315);
    final hoverColor = isDark ? const Color(0x0DE65100) : const Color(0x0DD84315);
    final splashColor = isDark ? const Color(0x1AE65100) : const Color(0x1AD84315);
    final inactiveTextColor = isDark ? Colors.white70 : const Color(0xFF37474F);

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
      width: isDesktop ? 280 : min(size.width * 0.86, 360.0),
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
        border: isDesktop
            ? Border(
                right: BorderSide(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  width: 1,
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Header Area
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.white24 : const Color(0xFFFFEBE5),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: isDark ? const Color(0x33D84315) : const Color(0xFFFFEBE5),
                            child: Text(
                              'WF',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFFF8A65) : const Color(0xFFD84315),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wassim Food',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentBranchName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isDesktop)
                          GestureDetector(
                            onTap: () => _closeDrawer(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 18),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      height: 1,
                    ),
                    const SizedBox(height: 16),

                    // Admin Profile Card
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFB300),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    adminName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0x26FFB300) : const Color(0xFFFFF8E1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.admin_panel_settings_outlined,
                                          size: 14,
                                          color: isDark ? const Color(0xFFFFB300) : const Color(0xFFF57C00),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          adminRole,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFFFFB300) : const Color(0xFFF57C00),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'ADMIN NAVIGATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Menu List
                    ...menuItems.map((item) {
                      final title = item['title'] as String;
                      final isActive = activeItem.toLowerCase() == title.toLowerCase();
                      final icon = isActive ? (item['activeIcon'] as IconData) : (item['icon'] as IconData);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onItemSelected(title),
                            borderRadius: BorderRadius.circular(14),
                            hoverColor: hoverColor,
                            splashColor: splashColor,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive ? activeBg : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  // Selected Left Indicator
                                  Container(
                                    width: 4,
                                    height: 16,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: isActive ? activeTextColor : Colors.transparent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Icon(
                                    icon,
                                    color: isActive
                                        ? activeTextColor
                                        : (isDark ? Colors.white54 : const Color(0xFF78909C)),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                        color: isActive ? activeTextColor : inactiveTextColor,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: isActive
                                        ? activeTextColor
                                        : (isDark ? Colors.white30 : const Color(0xFFB0BEC5)),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const Spacer(),
                    const SizedBox(height: 24),

                    // Modern Support Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.contact_support_outlined,
                                color: activeTextColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Contact Support',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Available 24/7 for technical issues.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => _showContactDialog(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: activeTextColor.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              minimumSize: const Size(double.infinity, 36),
                            ),
                            child: Text(
                              'Contact Help',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: activeTextColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Divider(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      height: 1,
                    ),
                    const SizedBox(height: 12),

                    // Copyright & Version Footer
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(
                            'Wassim Food © 2026',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Admin Portal • v1.2.0',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white30 : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Premium Logout Button
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
