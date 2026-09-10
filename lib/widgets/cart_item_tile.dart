import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../utils/helpers.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemTile({
    Key? key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final extrasText = item.selectedExtras.isEmpty
        ? 'No extras'
        : item.selectedExtras.map((e) => '${e.name} (+${CurrencyFormatter.formatDH(e.price)})').join(', ');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 76,
              height: 76,
              child: Image.network(
                item.menuItem.imageUrl.isNotEmpty
                    ? item.menuItem.imageUrl
                    : 'https://images.unsplash.com/photo-1495195134139-0d4517b28b9f?w=200&h=200&fit=crop',
                cacheWidth: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  child: Icon(Icons.fastfood_rounded, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItem.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  extrasText,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${CurrencyFormatter.formatDH(item.unitPrice)} each',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatDH(item.totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF8D4B38),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),
          // Quantity controls
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onDecrement,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.remove_rounded, size: 16, color: Color(0xFF8D4B38)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onIncrement,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.add_rounded, size: 16, color: Color(0xFF8D4B38)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
