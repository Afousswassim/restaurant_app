import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../utils/helpers.dart';

class PopularItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const PopularItemCard({Key? key, required this.item, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                item.imageUrl.isNotEmpty ? item.imageUrl : 'https://images.unsplash.com/photo-1495195134139-0d4517b28b9f?w=800&auto=format&fit=crop&q=80',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey.shade100,
                    child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepOrange))),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.fastfood, size: 36, color: Colors.grey),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.deepOrange),
                                const SizedBox(width: 6),
                                Text(item.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(child: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(CurrencyFormatter.formatDH(item.price), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      const Spacer(),
                      InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
