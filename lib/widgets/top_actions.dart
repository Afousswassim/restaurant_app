import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/notification_screen.dart';

class TopActions extends StatelessWidget {
  const TopActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<NotificationProvider, ThemeProvider, ClientProvider>(
      builder: (context, notificationProv, themeProv, clientProv, _) {
        final badgeCount = notificationProv.unreadCount;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              context: context,
              icon: Icons.notifications_none_rounded,
              badgeCount: badgeCount,
              tooltip: 'Notifications',
              onTap: () {
                if (clientProv.currentClient != null) {
                  notificationProv.loadNotifications(clientProv.currentClient!.id);
                }
                Navigator.of(context).pushNamed(NotificationScreen.routeName);
              },
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              context: context,
              icon: themeProv.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              tooltip: 'Toggle Theme',
              onTap: () => themeProv.toggleTheme(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    int badgeCount = 0,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final borderColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.06);
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
