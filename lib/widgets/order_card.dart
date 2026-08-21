import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/helpers.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'reward_redeemed':
        return const Color(0xFFF59E0B);
      case 'pending':
        return const Color(0xFFEA580C);
      case 'preparing':
        return const Color(0xFF0284C7);
      case 'delivering':
      case 'on-way':
      case 'ready':
        return const Color(0xFF7C3AED);
      case 'delivered':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBgColor(String status, bool isDark) {
    if (isDark) {
      switch (status.toLowerCase()) {
        case 'reward_redeemed':
          return const Color(0xFFF59E0B).withOpacity(0.15);
        case 'pending':
          return const Color(0xFFEA580C).withOpacity(0.15);
        case 'preparing':
          return const Color(0xFF0284C7).withOpacity(0.15);
        case 'delivering':
        case 'on-way':
        case 'ready':
          return const Color(0xFF7C3AED).withOpacity(0.15);
        case 'delivered':
          return const Color(0xFF16A34A).withOpacity(0.15);
        case 'cancelled':
          return const Color(0xFFDC2626).withOpacity(0.15);
        default:
          return Colors.white10;
      }
    } else {
      switch (status.toLowerCase()) {
        case 'reward_redeemed':
          return const Color(0xFFFEF3C7);
        case 'pending':
          return const Color(0xFFFFEDD5);
        case 'preparing':
          return const Color(0xFFE0F2FE);
        case 'delivering':
        case 'on-way':
        case 'ready':
          return const Color(0xFFF3E8FF);
        case 'delivered':
          return const Color(0xFFDCFCE7);
        case 'cancelled':
          return const Color(0xFFFEE2E2);
        default:
          return const Color(0xFFF1F5F9);
      }
    }
  }

  void _showOrderDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order Details #${order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Branch & Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 18, color: Colors.deepOrange),
                          const SizedBox(width: 8),
                          Text(
                            order.branch.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(order.status, isDark),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.statusDisplay,
                          style: TextStyle(
                            color: _getStatusColor(order.status, theme),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Customer & Delivery Details
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.customerName.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (order.phone.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(order.phone, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (order.address.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(order.address, style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        Row(
                          children: [
                            const Icon(Icons.payment_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Payment: ${order.paymentMethod.toUpperCase()}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('Items Ordered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),

                  // Order items list
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (item.selectedExtras.isNotEmpty)
                                    Text(
                                      'Extras: ${item.selectedExtras.map((e) => e.name).join(', ')}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatDH(item.totalPrice),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),

                  const Divider(height: 28),

                  // Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                      Text(CurrencyFormatter.formatDH(order.subtotal)),
                    ],
                  ),
                  if (order.deliveryFee > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee', style: TextStyle(color: Colors.grey)),
                        Text(CurrencyFormatter.formatDH(order.deliveryFee)),
                      ],
                    ),
                  ],
                  if (order.discount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount', style: TextStyle(color: Colors.green)),
                        Text('-${CurrencyFormatter.formatDH(order.discount)}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        CurrencyFormatter.formatDH(order.totalAmount),
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(order.status, theme);
    final statusBgColor = _getStatusBgColor(order.status, isDark);

    final idShort = order.id.length > 6
        ? order.id.substring(order.id.length - 6).toUpperCase()
        : order.id.toUpperCase();

    final formattedDate = '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} • ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Order ID + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        order.isReward ? Icons.card_giftcard_rounded : Icons.receipt_rounded,
                        size: 18,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.isReward ? 'REWARD' : 'ORDER'} #$idShort',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF2C1810),
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.statusDisplay,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
            const SizedBox(height: 12),

            // Branch info
            Row(
              children: [
                const Icon(Icons.storefront_rounded, size: 14, color: Colors.deepOrange),
                const SizedBox(width: 6),
                Text(
                  order.branch.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Products breakdown preview
            ...order.items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        '${item.quantity}x ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatDH(item.totalPrice),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                )),

            if (order.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${order.items.length - 3} more items',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
            const SizedBox(height: 12),

            // Footer: Total Price & View Details Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.isReward ? 'Points / Price' : 'Total Price',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatDH(order.totalAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showOrderDetails(context),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade100,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
