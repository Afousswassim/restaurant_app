import 'package:flutter/material.dart';
import '../widgets/client_navbar.dart';
import '../widgets/top_actions.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const ClientNavbar(
        title: 'Settings',
        showBackButton: true,
        showMenuButton: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 18),
              Text('Settings', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Adjust your preferences, theme, and app behavior here.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
