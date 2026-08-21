import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification.dart';
import '../providers/theme_provider.dart';
import '../widgets/client_navbar.dart';
import '../widgets/top_actions.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';

class NotificationScreen extends StatefulWidget {
  static const routeName = '/notifications';
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      final client = context.read<ClientProvider>().currentClient;
      final notificationProvider = context.read<NotificationProvider>();
      if (client != null) {
        notificationProvider.loadNotifications(client.id);
      }
      _didLoad = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final client = context.watch<ClientProvider>().currentClient;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: const ClientNavbar(
        title: 'Notifications',
        showBackButton: true,
        showMenuButton: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Consumer<NotificationProvider>(
          builder: (context, notificationProv, _) {
            if (client == null) {
              return Center(
                child: Text(
                  'Log in to view your notifications.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              );
            }

            if (notificationProv.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = notificationProv.notifications;
            final unreadCount = notificationProv.unreadCount;

            return Column(
              children: [
                if (notifications.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent updates',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: unreadCount > 0
                            ? () => notificationProv.markAllAsRead(client.id)
                            : null,
                        child: Text(
                          'Mark all as read',
                          style: textTheme.bodyMedium?.copyWith(
                            color: unreadCount > 0 ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: notifications.isEmpty
                      ? RefreshIndicator(
                          onRefresh: () => notificationProv.loadNotifications(client.id),
                          color: colorScheme.primary,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 72,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: Text(
                                  'No notifications yet',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Order updates will appear here as soon as they arrive.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => notificationProv.loadNotifications(client.id),
                          color: colorScheme.primary,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final item = notifications[index];
                              return _buildNotificationCard(context, item, notificationProv, colorScheme, textTheme);
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItem item,
    NotificationProvider notificationProv,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final backgroundColor = item.isRead
        ? Theme.of(context).cardColor
        : colorScheme.primaryContainer.withOpacity(0.16);
    final borderColor = item.isRead
        ? Theme.of(context).dividerColor
        : colorScheme.primary.withOpacity(0.25);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (!item.isRead) {
            notificationProv.markAsRead(item.id);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (!item.isRead)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.message,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Text(
                _formatDate(item.createdAt),
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
