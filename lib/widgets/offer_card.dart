import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../utils/helpers.dart';

class OfferCard extends StatelessWidget {
  final MenuItem offer;
  final VoidCallback onOrderTap;

  const OfferCard({super.key, required this.offer, required this.onOrderTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isOutOfStock = !offer.isAvailable;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Image.network(
                      offer.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      cacheWidth: 500,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        child: Icon(
                          Icons.fastfood_rounded,
                          size: 48,
                          color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    if (isOutOfStock)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6),
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
                    else
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            offer.offerLabel ?? 'OFFER',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyFormatter.formatDH(offer.price),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                CurrencyFormatter.formatDH(offer.effectivePrice),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8D4B38),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: isOutOfStock ? null : onOrderTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOutOfStock ? Colors.grey.shade400 : const Color(0xFF8D4B38),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isOutOfStock ? 'Out of Stock' : 'Order Now',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
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
