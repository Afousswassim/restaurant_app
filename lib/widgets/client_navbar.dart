import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/notification_screen.dart';

class ClientNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showMenuButton;
  final List<Widget>? extraActions;

  const ClientNavbar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = false,
    this.onBackPressed,
    this.showMenuButton = true,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();
    final bool isDetailBack = showBackButton || (onBackPressed != null) || (!showMenuButton && canPop);

    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // LEFT SIDE: Single Menu button OR Back arrow
            if (isDetailBack)
              _buildSquareIconButton(
                context: context,
                icon: Icons.arrow_back_rounded,
                onTap: onBackPressed ?? () => Navigator.of(context).maybePop(),
                tooltip: 'Back',
              )
            else if (showMenuButton)
              Builder(
                builder: (ctx) => _buildSquareIconButton(
                  context: ctx,
                  icon: Icons.menu_rounded,
                  onTap: () {
                    final scaffold = Scaffold.of(ctx);
                    if (scaffold.hasDrawer) {
                      scaffold.openDrawer();
                    } else if (scaffold.hasEndDrawer) {
                      scaffold.openEndDrawer();
                    }
                  },
                  tooltip: 'Menu',
                ),
              )
            else
              const SizedBox(width: 42),

            const SizedBox(width: 12),

            // CENTER: Title or Wassim Food branding
            Expanded(
              child: Center(
                child: titleWidget ?? _buildDefaultTitle(context, title, isDark),
              ),
            ),

            const SizedBox(width: 12),

            // RIGHT SIDE: Notification + Dark Mode Toggle
            Consumer3<NotificationProvider, ThemeProvider, ClientProvider>(
              builder: (context, notifProv, themeProv, clientProv, _) {
                final unreadCount = notifProv.unreadCount;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (extraActions != null) ...extraActions!,
                    // Notification Button with badge
                    _buildSquareIconButton(
                      context: context,
                      icon: Icons.notifications_none_rounded,
                      badgeCount: unreadCount,
                      tooltip: 'Notifications',
                      onTap: () {
                        if (clientProv.currentClient != null) {
                          notifProv.loadNotifications(clientProv.currentClient!.id);
                        }
                        Navigator.of(context).pushNamed(NotificationScreen.routeName);
                      },
                    ),
                    const SizedBox(width: 8),
                    // Dark Mode Switch Button
                    _buildSquareIconButton(
                      context: context,
                      icon: themeProv.isDarkMode
                          ? Icons.wb_sunny_outlined
                          : Icons.nightlight_round_outlined,
                      tooltip: 'Toggle Theme',
                      onTap: () => themeProv.toggleTheme(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultTitle(BuildContext context, String? titleText, bool isDark) {
    if (titleText != null && titleText.isNotEmpty) {
      return Text(
        titleText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF2C1810),
          letterSpacing: -0.3,
        ),
      );
    }

    // Default Wassim Food branding
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8D4B38), Color(0xFF6E392A)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8D4B38).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Wassim Food',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF8D4B38),
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSquareIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    int badgeCount = 0,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0);
    final iconColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
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
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          width: 1.5,
                        ),
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

