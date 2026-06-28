import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_recommendation.dart';
import '../providers/ai_provider.dart';
import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/client_provider.dart';
import '../screens/branch_selection_screen.dart';
import '../utils/helpers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_actions.dart';

class AiFoodAssistantScreen extends StatefulWidget {
  static const routeName = '/ai-food-assistant';

  const AiFoodAssistantScreen({super.key});

  @override
  State<AiFoodAssistantScreen> createState() => _AiFoodAssistantScreenState();
}

class _AiFoodAssistantScreenState extends State<AiFoodAssistantScreen> {
  final _budgetController = TextEditingController(text: '120');
  final _peopleController = TextEditingController(text: '2');

  String _mode = 'recommendation';
  String _goal = 'Healthy';
  String _preference = 'Any';

  final _goals = const ['Healthy', 'High Protein', 'Low Calories', 'Family Meal', 'Budget Friendly'];
  final _preferences = const ['Any', 'Burger', 'Pizza', 'Crepe', 'Dessert', 'Drinks'];

  @override
  void dispose() {
    _budgetController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    final branch = context.read<BranchProvider>().selectedBranch;
    final client = context.read<ClientProvider>().currentClient;

    if (branch == null) {
      Navigator.of(context).pushReplacementNamed(BranchSelectionScreen.routeName);
      return;
    }

    final ok = await context.read<AiProvider>().generatePlan(
          mode: _mode,
          clientId: client?.id,
          branchId: branch.id,
          goal: _goal,
          budget: double.tryParse(_budgetController.text.trim()) ?? 0,
          people: int.tryParse(_peopleController.text.trim()) ?? 1,
          preference: _preference,
        );

    if (!mounted || ok) return;
    final error = context.read<AiProvider>().error ?? 'Could not generate AI plan';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _addAllToCart(AiRecommendation recommendation) async {
    final branch = context.read<BranchProvider>().selectedBranch;
    if (branch == null) return;

    final cartProvider = context.read<CartProvider>();
    for (final item in recommendation.items) {
      await cartProvider.addToCart(item.menuItem, branch, 1, const []);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI meal plan added to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final branch = context.watch<BranchProvider>().selectedBranch;
    final aiProvider = context.watch<AiProvider>();
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);

    if (branch == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(BranchSelectionScreen.routeName);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('AI Food Assistant'),
        actions: const [TopActions()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 920),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _HeaderCard(branchName: branch.name),
              const SizedBox(height: 16),
              _ModeSelector(
                selectedMode: _mode,
                onChanged: (mode) {
                  setState(() {
                    _mode = mode;
                  });
                },
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_mode == 'nutrition')
                        DropdownButtonFormField<String>(
                          value: _goal,
                          decoration: const InputDecoration(
                            labelText: 'Nutrition goal',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: _goals.map((goal) => DropdownMenuItem(value: goal, child: Text(goal))).toList(),
                          onChanged: (value) => setState(() => _goal = value ?? _goal),
                        ),
                      if (_mode == 'meal_planner') ...[
                        TextFormField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Budget in DH',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _peopleController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Number of people',
                            prefixIcon: Icon(Icons.group_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _preference,
                          decoration: const InputDecoration(
                            labelText: 'Food preference',
                            prefixIcon: Icon(Icons.restaurant_menu_outlined),
                          ),
                          items: _preferences.map((preference) => DropdownMenuItem(value: preference, child: Text(preference))).toList(),
                          onChanged: (value) => setState(() => _preference = value ?? _preference),
                        ),
                      ],
                      if (_mode == 'recommendation')
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.history_outlined, color: colorScheme.primary),
                          title: const Text('Based on your previous orders'),
                          subtitle: const Text('The assistant detects your favorite categories and suggests matching products.'),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: aiProvider.isLoading ? null : _generatePlan,
                          icon: aiProvider.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Generate AI Plan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (aiProvider.recommendation != null)
                _ResultSection(
                  recommendation: aiProvider.recommendation!,
                  onAddAll: () => _addAllToCart(aiProvider.recommendation!),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String branchName;

  const _HeaderCard({required this.branchName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: const Icon(Icons.smart_toy_outlined),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Smart Food Assistant',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Smart suggestions based on your taste and goals',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  branchName,
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onChanged;

  const _ModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final modes = [
      _ModeOption('recommendation', 'Recommendations', Icons.recommend_outlined),
      _ModeOption('nutrition', 'Nutrition Assistant', Icons.eco_outlined),
      _ModeOption('meal_planner', 'Meal Planner', Icons.event_note_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: modes.map((mode) {
            return SizedBox(
              width: isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth,
              child: _ModeCard(
                option: mode,
                isSelected: selectedMode == mode.value,
                onTap: () => onChanged(mode.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ModeOption {
  final String value;
  final String label;
  final IconData icon;

  const _ModeOption(this.value, this.label, this.icon);
}

class _ModeCard extends StatelessWidget {
  final _ModeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(option.icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final AiRecommendation recommendation;
  final VoidCallback onAddAll;

  const _ResultSection({
    required this.recommendation,
    required this.onAddAll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatDH(recommendation.total),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(recommendation.reason),
            const SizedBox(height: 16),
            ...recommendation.items.map((item) => _AiItemTile(item: item)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: recommendation.items.isEmpty ? null : onAddAll,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Add All To Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiItemTile extends StatelessWidget {
  final AiRecommendationItem item;

  const _AiItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final menuItem = item.menuItem;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              menuItem.imageUrl,
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 78,
                height: 78,
                color: colorScheme.surfaceVariant,
                child: const Icon(Icons.fastfood_outlined),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        menuItem.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatDH(menuItem.effectivePrice),
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${menuItem.category} - ${menuItem.calories} cal - ${menuItem.protein}g protein',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  item.reason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
