import 'package:flutter/material.dart';
import '../widgets/top_actions.dart';
import '../widgets/app_drawer.dart';

class FavoritesScreen extends StatelessWidget {
  static const routeName = '/favorites';
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        title: Text('My Favorites', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: theme.dividerColor)),
        actions: const [TopActions()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 18),
              Text('No favorites yet', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Tap the heart icon on your favorite meals to save them here for easy reorder.',
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
