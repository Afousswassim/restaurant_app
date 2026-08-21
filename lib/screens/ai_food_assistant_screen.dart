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
import '../widgets/client_navbar.dart';

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

  final List<Map<String, dynamic>> _quickPrompts = const [
    {
      'label': '🥗 High Protein under 80 DH',
      'mode': 'nutrition',
      'goal': 'High Protein',
      'budget': '80',
      'people': '1',
      'preference': 'Burger',
    },
    {
      'label': '🔥 Best Deals Combo for 2',
      'mode': 'meal_planner',
      'goal': 'Family Meal',
      'budget': '150',
      'people': '2',
      'preference': 'Burger',
    },
    {
      'label': '🌱 Healthy Low Calorie',
      'mode': 'nutrition',
      'goal': 'Low Calories',
      'budget': '100',
      'people': '1',
      'preference': 'Any',
    },
    {
      'label': '🍔 Budget Meal under 50 DH',
      'mode': 'meal_planner',
      'goal': 'Budget Friendly',
      'budget': '50',
      'people': '1',
      'preference': 'Burger',
    },
  ];

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleQuickPrompt(Map<String, dynamic> prompt) async {
    setState(() {
      _mode = prompt['mode'];
      _goal = prompt['goal'];
      _budgetController.text = prompt['budget'];
      _peopleController.text = prompt['people'];
      _preference = prompt['preference'];
    });
    await _generatePlan();
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
      const SnackBar(
        content: Text('✨ AI meal plan added to your cart!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      drawer: const AppDrawer(),
      appBar: const ClientNavbar(title: 'AI Food Assistant'),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 900),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              // Hero Welcome Banner
              _buildHeroHeader(theme, branch.name, isDark),
              const SizedBox(height: 20),

              // Interactive Mode Selector Tabs
              _buildModeSelector(isDark),
              const SizedBox(height: 16),

              // Suggested Quick Prompt Chips
              _buildQuickPrompts(isDark),
              const SizedBox(height: 16),

              // Inputs Card
              _buildInputCard(theme, isDark, aiProvider),
              const SizedBox(height: 24),

              // AI Output Section or Empty State
              if (aiProvider.isLoading)
                _buildLoadingState(isDark)
              else if (aiProvider.recommendation != null)
                _ResultSection(
                  recommendation: aiProvider.recommendation!,
                  onAddAll: () => _addAllToCart(aiProvider.recommendation!),
                )
              else
                _buildEmptyState(isDark),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildHeroHeader(ThemeData theme, String branchName, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepOrange, Color(0xFFD84315)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Smart Food Assistant',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Personalized meals tailored to your taste, budget & nutrition goals.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        branchName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildModeSelector(bool isDark) {
    final modes = [
      {'value': 'recommendation', 'label': 'Smart Suggestions', 'icon': Icons.lightbulb_outlined},
      {'value': 'nutrition', 'label': 'Nutrition Assistant', 'icon': Icons.eco_outlined},
      {'value': 'meal_planner', 'label': 'Meal Planner', 'icon': Icons.event_note_outlined},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 650;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: modes.map((m) {
            final isSelected = _mode == m['value'];
            final width = isWide ? (constraints.maxWidth - 20) / 3 : constraints.maxWidth;
            return SizedBox(
              width: width,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _mode = m['value'] as String),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepOrange
                          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepOrange
                            : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? Colors.deepOrange.withOpacity(0.25)
                              : Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          m['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.deepOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            m['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF2C1810)),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuickPrompts(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 16, color: Colors.deepOrange),
            const SizedBox(width: 6),
            Text(
              'Quick AI Suggestions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _quickPrompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final prompt = _quickPrompts[index];
              return InkWell(
                onTap: () => _handleQuickPrompt(prompt),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282828) : Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.deepOrange.shade100,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      prompt['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.deepOrange.shade900,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(ThemeData theme, bool isDark, AiProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_mode == 'nutrition') ...[
            DropdownButtonFormField<String>(
              value: _goal,
              decoration: InputDecoration(
                labelText: 'Nutrition Goal',
                prefixIcon: const Icon(Icons.flag_outlined, color: Colors.deepOrange),
                filled: true,
                fillColor: isDark ? const Color(0xFF282828) : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _goals
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) => setState(() => _goal = val ?? _goal),
            ),
          ],
          if (_mode == 'meal_planner') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Budget (DH)',
                      prefixIcon: const Icon(Icons.payments_outlined, color: Colors.deepOrange),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF282828) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _peopleController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'People',
                      prefixIcon: const Icon(Icons.group_outlined, color: Colors.deepOrange),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF282828) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _preference,
              decoration: InputDecoration(
                labelText: 'Food Preference',
                prefixIcon: const Icon(Icons.restaurant_menu_outlined, color: Colors.deepOrange),
                filled: true,
                fillColor: isDark ? const Color(0xFF282828) : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _preferences
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) => setState(() => _preference = val ?? _preference),
            ),
          ],
          if (_mode == 'recommendation')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: Colors.deepOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI will analyze your previous order history and branch menu to suggest perfect choices for you.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.deepOrange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: aiProvider.isLoading ? null : _generatePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: aiProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                aiProvider.isLoading ? 'Analyzing Menu...' : 'Generate AI Meal Plan',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Colors.deepOrange),
          const SizedBox(height: 16),
          const Text(
            '🤖 Crafting your custom meal plan...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Comparing nutrients, availability, and best deals.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 48, color: Colors.deepOrange),
          ),
          const SizedBox(height: 16),
          const Text(
            'What are you in the mood for?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a mode or tap one of the quick suggestions above to let your AI assistant generate a tailored recommendation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.deepOrange, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          recommendation.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.formatDH(recommendation.total),
                  style: const TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                recommendation.reason,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Recommended Products',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ...recommendation.items.map((item) => _AiItemTile(item: item)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: recommendation.items.isEmpty ? null : onAddAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text(
                  'Add Entire AI Meal Plan to Cart',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282828) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              menuItem.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade300,
                child: const Icon(Icons.fastfood_outlined, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        menuItem.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatDH(menuItem.effectivePrice),
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${menuItem.category} • ${menuItem.calories} kcal • ${menuItem.protein}g protein',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.reason,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
