import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../utils/helpers.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/bottom_nav_bar.dart';
import 'checkout_screen.dart';
import 'home_screen.dart';
import '../widgets/client_navbar.dart';
import '../widgets/top_actions.dart';
import '../widgets/app_drawer.dart';

class CartScreen extends StatefulWidget {
  static const routeName = '/cart';

  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: ClientNavbar(
        title: 'My Cart',
        extraActions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Tooltip(
                message: 'Clear Cart',
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06), width: 1),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        if (cart.items.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cart is already empty')),
                          );
                          return;
                        }
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear cart?'),
                            content: const Text('Are you sure you want to remove all items?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await cart.clearCart();
                        }
                      },
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
          ),
          child: Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              if (cartProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                  ),
                );
              }

              final cartItems = cartProvider.items;

              if (cartItems.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 96,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Your cart is empty',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Go back to the menu and add some delicious meals!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.pop(context);
                            } else {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Browse Menu'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final branch = cartProvider.selectedBranch;

              return Column(
                children: [
                  // Selected Branch bar
                  if (branch != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.deepOrange.shade50,
                      child: Row(
                        children: [
                          const Icon(Icons.storefront, size: 20, color: Colors.deepOrange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ordering from: ${branch.name}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Cart Items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return CartItemTile(
                          item: item,
                          onIncrement: () => cartProvider.increaseQuantity(item),
                          onDecrement: () => cartProvider.decreaseQuantity(item),
                          onRemove: () => cartProvider.removeItem(item),
                        );
                      },
                    ),
                  ),

                  // Cart Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          offset: const Offset(0, -4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(
                              CurrencyFormatter.formatDH(cartProvider.subtotal),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Fee'),
                            Text(
                              CurrencyFormatter.formatDH(cartProvider.deliveryFee),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatDH(cartProvider.total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Proceed to Checkout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}
