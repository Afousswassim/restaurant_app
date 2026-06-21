import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final clientProvider = context.watch<ClientProvider>();
    final client = clientProvider.currentClient;
    final initials = _getInitials(client?.fullName ?? 'WF');
    final isAuthenticated = clientProvider.isAuthenticated;
    final drawerWidth = min(size.width * 0.86, 360.0);
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final isDarkMode = theme.brightness == Brightness.dark;

    return Drawer(
      width: drawerWidth,
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, isDarkMode),
                        const SizedBox(height: 12),
                        Divider(
                          color: isDarkMode ? Colors.white10 : const Color(0xFFF1F5F9),
                          height: 1,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileCard(context, client, initials, isAuthenticated, isDarkMode),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'QUICK NAVIGATION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white38 : const Color(0xFF94A3B8),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _DrawerItem(
                          icon: Icons.restaurant_menu_outlined,
                          label: 'Home Dashboard',
                          isActive: currentRoute == '/home' || currentRoute == '/' || currentRoute == '',
                          onTap: () => _navigateNamed(context, '/home', replaceAll: true),
                        ),
                        _DrawerItem(
                          icon: Icons.receipt_long_outlined,
                          label: 'My Orders',
                          isActive: currentRoute == '/orders',
                          onTap: () => _navigateNamed(context, '/orders'),
                        ),
                        _DrawerItem(
                          icon: Icons.card_giftcard_outlined,
                          label: 'Special Offers & Deals',
                          isActive: currentRoute == '/offers',
                          onTap: () => _navigateNamed(context, '/offers'),
                          trailingBadge: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD54F),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'new',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                        ),
                        _DrawerItem(
                          icon: Icons.phone_outlined,
                          label: 'Contact Us',
                          isActive: false,
                          onTap: () => _showContactDialog(context),
                        ),
                        _DrawerItem(
                          icon: Icons.person_outline,
                          label: 'Update Profile',
                          isActive: currentRoute == '/client-profile',
                          onTap: () => _navigateNamed(context, '/client-profile'),
                        ),
                        _DrawerItem(
                          icon: Icons.location_on_outlined,
                          label: 'Change Branch',
                          isActive: currentRoute == '/branch-selection',
                          onTap: () => _navigateNamed(context, '/branch-selection'),
                        ),
                        _DrawerItem(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          isActive: currentRoute == '/settings',
                          onTap: () => _navigateNamed(context, '/settings'),
                        ),
                        const Spacer(),
                        const SizedBox(height: 24),
                        Divider(
                          color: isDarkMode ? Colors.white10 : const Color(0xFFF1F5F9),
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Text(
                                'Wassim Food © 2026',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white38 : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fast Delivery • Fresh Food 🥞 🔥',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white30 : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDarkMode ? Colors.white24 : const Color(0xFFFFEBE5),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: isDarkMode ? const Color(0x33D84315) : const Color(0xFFFFEBE5),
            child: Text(
              'WF',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? const Color(0xFFFF8A65) : const Color(0xFFD84315),
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
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'NASR CITY ORIGINAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white38 : const Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white10 : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: 18,
              color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    dynamic client,
    String initials,
    bool isAuthenticated,
    bool isDarkMode,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
                        isAuthenticated ? (client?.fullName ?? 'Guest') : 'Guest User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0x26FFB300) : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 14,
                              color: isDarkMode ? const Color(0xFFFFB300) : const Color(0xFFF57C00),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Points: ${isAuthenticated ? (client?.loyaltyPoints ?? 0) : 0}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? const Color(0xFFFFB300) : const Color(0xFFF57C00),
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
            const SizedBox(height: 12),
            Divider(
              color: isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0),
              height: 1,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton(
                onPressed: () {
                  if (isAuthenticated) {
                    _handleLogout(context);
                  } else {
                    _navigateNamed(context, '/client-login');
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: isAuthenticated
                      ? (isDarkMode ? const Color(0x26D32F2F) : const Color(0xFFFFEBEE))
                      : (isDarkMode ? const Color(0x26E65100) : const Color(0xFFFFF3E0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAuthenticated ? Icons.logout : Icons.login,
                      size: 18,
                      color: isAuthenticated
                          ? (isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFD32F2F))
                          : (isDarkMode ? const Color(0xFFFFB74D) : const Color(0xFFE65100)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAuthenticated ? 'Log out & Clear profile' : 'Log In / Register',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isAuthenticated
                            ? (isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFD32F2F))
                            : (isDarkMode ? const Color(0xFFFFB74D) : const Color(0xFFE65100)),
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

  String _getInitials(String fullName) {
    final words = fullName.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return fullName.isEmpty ? 'WF' : fullName.substring(0, min(2, fullName.length)).toUpperCase();
  }

  void _handleLogout(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final navigator = Navigator.of(context);
    final clientProvider = context.read<ClientProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      navigator.pop(); // dismiss drawer
      await clientProvider.logout();
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  void _showContactDialog(BuildContext context) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Contact Wassim Food'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ListTile(
                leading: Icon(Icons.chat, color: Colors.green),
                title: Text('WhatsApp'),
                subtitle: Text('+212 600 123 456'),
              ),
              SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.deepOrange),
                title: Text('Phone'),
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

  void _navigateNamed(BuildContext context, String route, {bool replaceAll = false}) {
    Navigator.of(context).pop();
    if (replaceAll) {
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Widget? trailingBadge;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final activeBg = isDarkMode
        ? const Color(0x26E65100)
        : const Color(0xFFFFEBE5);
    final activeTextColor = isDarkMode
        ? const Color(0xFFFF8A65)
        : const Color(0xFFD84315);

    final hoverColor = isDarkMode
        ? const Color(0x0DE65100)
        : const Color(0x0DD84315);
    final splashColor = isDarkMode
        ? const Color(0x1AE65100)
        : const Color(0x1AD84315);

    final inactiveTextColor = isDarkMode ? Colors.white70 : const Color(0xFF37474F);
    final iconColor = isActive
        ? activeTextColor
        : (isDarkMode ? Colors.white54 : const Color(0xFF78909C));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive ? activeTextColor : inactiveTextColor,
                    ),
                  ),
                ),
                if (trailingBadge != null) ...[
                  trailingBadge!,
                  const SizedBox(width: 8),
                ],
                Icon(
                  Icons.chevron_right,
                  color: isActive
                      ? activeTextColor
                      : (isDarkMode ? Colors.white30 : const Color(0xFFB0BEC5)),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
