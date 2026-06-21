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
        final theme = Theme.of(context);
        final isDark = themeProv.isDarkMode;
        final iconColor = theme.colorScheme.onSurface;
        final badgeCount = notificationProv.unreadCount;
        final scaffoldState = Scaffold.maybeOf(context);
        final hasEndDrawer = scaffoldState?.widget.endDrawer != null;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasEndDrawer)
              Row(
                children: [
                  _buildActionButton(
                    context: context,
                    child: Icon(Icons.menu, color: iconColor, size: 20),
                    onTap: scaffoldState?.openEndDrawer ?? () {},
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            _buildActionButton(
              context: context,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none,
                    color: iconColor,
                    size: 20,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                if (clientProv.currentClient != null) {
                  notificationProv.loadNotifications(clientProv.currentClient!.id);
                }
                Navigator.of(context).pushNamed(NotificationScreen.routeName);
              },
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              context: context,
              child: Icon(
                isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: iconColor,
                size: 20,
              ),
              onTap: () => themeProv.toggleTheme(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({required BuildContext context, required Widget child, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(child: child),
        ),
      ),
    );
  }
}
