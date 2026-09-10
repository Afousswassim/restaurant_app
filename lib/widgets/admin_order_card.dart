import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/helpers.dart';
import '../screens/admin_order_details_screen.dart';

class AdminOrderCard extends StatefulWidget {
  final Order order;
  final Function(String) onUpdateStatus;
  final bool isUpdating;

  const AdminOrderCard({
    Key? key,
    required this.order,
    required this.onUpdateStatus,
    this.isUpdating = false,
  }) : super(key: key);

  @override
  State<AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<AdminOrderCard> {
  late String _selectedStatus;
  final List<String> _statusList = ['pending', 'preparing', 'delivering', 'delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
  }

  @override
  void didUpdateWidget(covariant AdminOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.status != widget.order.status) {
      _selectedStatus = widget.order.status;
    }
  }

  Color _getStatusColor(String status) {
    return OrderStatusUtil.getStatusColor(status);
  }

  Color _getStatusBgColor(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OrderStatusUtil.getStatusBgColor(status, isDark);
  }

  String _getStatusDisplay(String status) {
    return OrderStatusUtil.getStatusDisplay(status);
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminOrderDetailsScreen(
          order: widget.order,
          onUpdateStatus: widget.onUpdateStatus,
          isUpdating: widget.isUpdating,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final statusColor = _getStatusColor(widget.order.status);
    final statusBgColor = _getStatusBgColor(widget.order.status);
    final hasStatusChanged = _selectedStatus != widget.order.status;

    final formattedId = widget.order.id.length > 8
        ? widget.order.id.substring(0, 8).toUpperCase()
        : widget.order.id.toUpperCase();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor),
      ),
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference Design Header: Order Icon + Order ID + Order Type Pill Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order ID: #$formattedId',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.order.orderType.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.order.createdAt.hour}:${widget.order.createdAt.minute.toString().padLeft(2, '0')}, ${widget.order.createdAt.day}/${widget.order.createdAt.month}/${widget.order.createdAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer & Total Info (Reference Layout)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Customer: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            widget.order.customerName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Total: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatDH(widget.order.totalAmount),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // See Details Link (Reference Design Action)
                  TextButton.icon(
                    onPressed: () => _navigateToDetails(context),
                    icon: Text(
                      'See Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    label: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status Pill + Quick Update Bar
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _getStatusDisplay(widget.order.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? const Color(0xFF1E1E26) : Colors.grey.shade100,
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        dropdownColor: theme.cardColor,
                        icon: const Icon(Icons.arrow_drop_down, size: 18),
                        items: _statusList.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(
                              _getStatusDisplay(status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newStatus) {
                          if (newStatus != null) {
                            setState(() {
                              _selectedStatus = newStatus;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  if (hasStatusChanged) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: widget.isUpdating
                          ? null
                          : () => widget.onUpdateStatus(_selectedStatus),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 36),
                      ),
                      child: widget.isUpdating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
