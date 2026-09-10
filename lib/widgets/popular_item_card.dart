import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../utils/helpers.dart';

class PopularItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const PopularItemCard({Key? key, required this.item, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isActiveOffer = item.isCurrentlyActiveOffer;
    bool isOutOfStock = !item.isAvailable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 115,
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
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      Image.network(
                        item.imageUrl.isNotEmpty ? item.imageUrl : 'https://images.unsplash.com/photo-1495195134139-0d4517b28b9f?w=800&auto=format&fit=crop&q=80',
                        width: double.infinity,
                        height: double.infinity,
                        cacheWidth: 350,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8D4B38)))),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          child: Icon(Icons.fastfood, size: 36, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                        ),
                      ),
                      if (isOutOfStock)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: const Center(
                            child: Text(
                              'UNAVAILABLE',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF8D4B38).withValues(alpha: 0.18)
                                  : const Color(0xFFF9EFEA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFF8D4B38)),
                                const SizedBox(width: 4),
                                Text(
                                  item.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Color(0xFF8D4B38),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isActiveOffer)
                        Text(
                          CurrencyFormatter.formatDH(item.price),
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      if (isActiveOffer) const SizedBox(width: 4),
                      Text(
                        CurrencyFormatter.formatDH(item.effectivePrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF8D4B38),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: isOutOfStock ? null : onTap,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: isOutOfStock
                                ? null
                                : const LinearGradient(
                                    colors: [Color(0xFF8D4B38), Color(0xFF6E392A)],
                                  ),
                            color: isOutOfStock ? (isDark ? Colors.white12 : Colors.grey.shade300) : null,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isOutOfStock
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF8D4B38).withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            isOutOfStock ? Icons.block_rounded : Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
}
}
