import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/branch_provider.dart';
import '../providers/menu_provider.dart';
import 'branch_selection_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      await context.read<CartProvider>().loadCart();

      // Extract branchId from deep link URL
      final branchId = _extractBranchIdFromUrl();

      if (branchId != null && branchId.isNotEmpty) {
        // Deep link detected: navigate directly to menu
        final branchProvider = context.read<BranchProvider>();
        final menuProvider = context.read<MenuProvider>();

        // Find and select branch by ID (this also loads branches if needed)
        await branchProvider.selectBranchById(branchId);
        final selectedBranch = branchProvider.selectedBranch;

        if (selectedBranch != null) {
          // Load menu for this branch
          await menuProvider.loadMenu(selectedBranch.id);

          if (!mounted) return;

          // Navigate directly to menu
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const MenuScreen(),
            ),
          );
          return;
        }
      }

      // No deep link: show normal branch selection
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BranchSelectionScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      // Navigate to branch selection on error
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BranchSelectionScreen()),
      );
    }
  }

  /// Extract branchId or slug from URL fragments, path, and query parameters.
  /// Handles:
  /// - Path routing: /menu/maarif
  /// - Hash routing: #/menu/maarif or #/menu?branchId=ID
  /// - Query routing: ?branchId=ID
  String? _extractBranchIdFromUrl() {
    final base = Uri.base;

    // 1. Direct path routing: /menu/:slug (e.g., /menu/maarif)
    final pathSegments = base.pathSegments;
    if (pathSegments.length >= 2 && pathSegments[0] == 'menu') {
      return pathSegments[1];
    }

    // 2. Hash fragment routing: #/menu/:slug or #/menu?branchId=slug
    if (base.fragment.isNotEmpty) {
      final fragment = base.fragment;
      final cleanFragment = fragment.startsWith('#') ? fragment.substring(1) : fragment;
      final uri = Uri.parse(cleanFragment.startsWith('/') ? cleanFragment : '/$cleanFragment');

      final segs = uri.pathSegments;
      if (segs.length >= 2 && segs[0] == 'menu') {
        return segs[1];
      }

      if (uri.queryParameters.containsKey('branchId')) {
        return uri.queryParameters['branchId'];
      }
    }

    // 3. Direct query parameters (e.g., ?branchId=ID)
    if (base.queryParameters.containsKey('branchId')) {
      return base.queryParameters['branchId'];
    }

    return null;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.shade400,
              Colors.deepOrange.shade600,
            ],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.restaurant_menu,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  'Wassim Food',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Legendary Flavor',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                    strokeWidth: 3,
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
