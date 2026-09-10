import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../utils/helpers.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isActiveOffer = item.isCurrentlyActiveOffer;
    final isOutOfStock = !item.isAvailable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image Stack
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(
                        item.imageUrl.isNotEmpty
                            ? item.imageUrl
                            : 'https://images.unsplash.com/photo-1495195134139-0d4517b28b9f?w=800&auto=format&fit=crop&q=80',
                        width: double.infinity,
                        height: double.infinity,
                        cacheWidth: 400,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          child: Icon(
                            Icons.fastfood_rounded,
                            size: 38,
                            color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                          ),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: double.infinity,
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF8D4B38),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Out Of Stock Overlay
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  // Active Offer Badge
                  else if (isActiveOffer)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8D4B38), Color(0xFF6E392A)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8D4B38).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          item.offerLabel ?? 'OFFER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  if (isActiveOffer && !isOutOfStock)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Limited time',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Product Info & Price
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF8D4B38).withValues(alpha: 0.18)
                                : const Color(0xFFF9EFEA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFF8D4B38)),
                              const SizedBox(width: 3),
                              Text(
                                item.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Color(0xFF8D4B38),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Prices & Action Button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isActiveOffer)
                                Text(
                                  CurrencyFormatter.formatDH(item.price),
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                CurrencyFormatter.formatDH(item.effectivePrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF8D4B38),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: isOutOfStock ? null : onTap,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: isOutOfStock
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFF8D4B38), Color(0xFF6E392A)],
                                    ),
                              color: isOutOfStock
                                  ? (isDark ? Colors.white12 : Colors.grey.shade300)
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isOutOfStock
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF8D4B38).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                            ),
                            child: Icon(
                              isOutOfStock ? Icons.block_rounded : Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
