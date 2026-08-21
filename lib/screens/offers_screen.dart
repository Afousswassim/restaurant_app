import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offers_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/offer_card.dart';
import '../widgets/coupon_card.dart';
import '../widgets/loyalty_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/client_navbar.dart';
import '../widgets/top_actions.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/client_provider.dart';

class OffersScreen extends StatefulWidget {
  static const routeName = '/offers';

  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OffersProvider>().loadOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final themeProv = context.watch<ThemeProvider>();
    final offersProvider = context.watch<OffersProvider>();
    final clientProvider = context.watch<ClientProvider>();
    final cartProvider = context.read<CartProvider>();

    final offerItems = offersProvider.offers;
    final bool hasNoOffers = offerItems.isEmpty && !offersProvider.isLoading;

    return Scaffold(
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(currentIndex: -1),
      appBar: const ClientNavbar(title: 'Special Offers'),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: offersProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                  ),
                )
              : hasNoOffers
                  ? _buildEmptyState(theme)
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroBanner(theme),
                          const SizedBox(height: 24),
                          _buildSectionTitle(theme, '🔥 Today\'s Best Deals'),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final itemWidth = constraints.maxWidth < 700
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth / 2) - 10;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: offerItems.map((offer) {
                                  return SizedBox(
                                    width: itemWidth,
                                    child: OfferCard(
                                      offer: offer,
                                      onOrderTap: () async {
                                        final branchProvider = context.read<BranchProvider>();
                                        final selectedBranch = branchProvider.selectedBranch;
                                        if (selectedBranch == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please select a branch first.'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        try {
                                          await cartProvider.addToCart(offer, selectedBranch, 1, []);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${offer.name} added to cart with offer price!'),
                                                backgroundColor: Colors.green,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(e.toString()),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          _buildSectionTitle(theme, '🎫 Exclusive Coupons'),
                          const SizedBox(height: 12),
                          const CouponCard(
                            code: 'WELCOME20',
                            description: '20% OFF first order.',
                          ),
                          const CouponCard(
                            code: 'BURGER50',
                            description: '50 DH discount on burger combo.',
                          ),
                          const CouponCard(
                            code: 'FREESHIP',
                            description: 'Free delivery on orders above 150 DH.',
                          ),
                          const SizedBox(height: 28),
                          _buildSectionTitle(theme, '⭐ Loyalty Rewards'),
                          const SizedBox(height: 12),
                          LoyaltyCard(
                            points: clientProvider.currentClient?.loyaltyPoints ?? 0,
                            onRedeemTap: () async {
                              if (!clientProvider.isAuthenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please login to redeem rewards')),
                                );
                                return;
                              }
                              final rewardType = await showDialog<String>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Select Reward'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: ListTile(
                                          title: const Text('Free Drink (300 pts)'),
                                          onTap: () => Navigator.pop(ctx, 'drink'),
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: ListTile(
                                          title: const Text('Free Burger (500 pts)'),
                                          onTap: () => Navigator.pop(ctx, 'burger'),
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: ListTile(
                                          title: const Text('Free Meal (1000 pts)'),
                                          onTap: () => Navigator.pop(ctx, 'meal'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              if (rewardType != null) {
                                try {
                                  final res = await clientProvider.redeemReward(rewardType);
                                  if (res != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Redeemed! ${res['rewardName']}'),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎁',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 18),
            Text(
              'No offers available today.',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Check again tomorrow for new promotions.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _buildHeroBanner(ThemeData theme) {
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
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '🔥 Today\'s Best Deals',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Save up to 50% on your favorite meals.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 14),
                _CountdownTicker(),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: Colors.white30,
                child: const Icon(Icons.fastfood, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownTicker extends StatefulWidget {
  const _CountdownTicker();

  @override
  State<_CountdownTicker> createState() => _CountdownTickerState();
}

class _CountdownTickerState extends State<_CountdownTicker> {
  late Timer _timer;
  int _secondsRemaining = 3 * 3600 + 24 * 60 + 15;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration() {
    final h = (_secondsRemaining ~/ 3600).toString().padLeft(2, '0');
    final m = ((_secondsRemaining % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x7F000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            'Ends in: ${_formatDuration()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

