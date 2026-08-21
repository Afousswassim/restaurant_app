import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/order.dart';
import '../utils/helpers.dart';

class AdminOrderDetailsScreen extends StatefulWidget {
  final Order order;
  final Function(String) onUpdateStatus;
  final bool isUpdating;

  const AdminOrderDetailsScreen({
    Key? key,
    required this.order,
    required this.onUpdateStatus,
    this.isUpdating = false,
  }) : super(key: key);

  @override
  State<AdminOrderDetailsScreen> createState() => _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  @override
  void didUpdateWidget(covariant AdminOrderDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.status != widget.order.status) {
      _currentStatus = widget.order.status;
    }
  }

  String _formatDate(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day-$month-$year, $hour12:$minute $period';
  }

  String _formatDateFancy(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = months[dt.month - 1];
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period, ${dt.day} $monthName ${dt.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'preparing':
        return const Color(0xFF4CAF50);
      case 'delivering':
        return const Color(0xFF2196F3);
      case 'delivered':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF757575);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF3E0);
      case 'preparing':
        return const Color(0xFFE8F5E9);
      case 'delivering':
        return const Color(0xFFE3F2FD);
      case 'delivered':
        return const Color(0xFFE8F5E9);
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'preparing':
        return 'Preparing';
      case 'delivering':
        return 'Delivering';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Unknown';
    }
  }

  Future<void> _printInvoice(BuildContext context) async {
    try {
      final doc = pw.Document();
      final order = widget.order;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Wassim Food',
                          style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.deepOrange,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          order.branch.name,
                          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 16),
                  child: pw.Divider(),
                ),

                // Order Meta Information
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CUSTOMER INFORMATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.Text(order.customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.Text(order.phone, style: const pw.TextStyle(fontSize: 11)),
                        pw.Text(order.address, style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('ORDER DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.Text('Date: ${_formatDate(order.createdAt)}', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('Payment: ${order.paymentMethod.toUpperCase()}', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('Status: ${order.statusDisplay.toUpperCase()}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Table Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 4, child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                      pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 2, child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.right)),
                      pw.Expanded(flex: 2, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ),

                // Items List
                ...order.items.map((item) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                              if (item.selectedExtras.isNotEmpty)
                                pw.Text(
                                  'Extras: ${item.selectedExtras.map((e) => e.name).join(', ')}',
                                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                                ),
                            ],
                          ),
                        ),
                        pw.Expanded(flex: 1, child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 12), textAlign: pw.TextAlign.center)),
                        pw.Expanded(flex: 2, child: pw.Text(CurrencyFormatter.formatDH(item.unitPrice), style: const pw.TextStyle(fontSize: 12), textAlign: pw.TextAlign.right)),
                        pw.Expanded(flex: 2, child: pw.Text(CurrencyFormatter.formatDH(item.totalPrice), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  );
                }).toList(),

                pw.SizedBox(height: 20),

                // Financial Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 240,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 12)),
                              pw.Text(CurrencyFormatter.formatDH(order.subtotal), style: const pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Delivery Fee:', style: const pw.TextStyle(fontSize: 12)),
                              pw.Text(CurrencyFormatter.formatDH(order.deliveryFee), style: const pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                          if (order.discount > 0) ...[
                            pw.SizedBox(height: 4),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Discount:', style: const pw.TextStyle(fontSize: 12, color: PdfColors.green)),
                                pw.Text('-${CurrencyFormatter.formatDH(order.discount)}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.green)),
                              ],
                            ),
                          ],
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 8),
                            child: pw.Divider(),
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Total Amount:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                              pw.Text(CurrencyFormatter.formatDH(order.totalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.deepOrange)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Footer
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('Thank you for choosing Wassim Food!', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text('For inquiries, contact support at Wassim Food Morocco.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'invoice_${order.id}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing invoice: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final order = widget.order;
    final statusColor = _getStatusColor(_currentStatus);
    final statusBgColor = _getStatusBgColor(_currentStatus);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121217) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E26) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: primaryColor,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Order Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _printInvoice(context),
            icon: Icon(Icons.print_outlined, color: primaryColor),
            tooltip: 'Print Invoice',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Order Header Summary Card (Reference Layout Top Section)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Order ID: #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getStatusDisplay(_currentStatus),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateFancy(order.createdAt),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: theme.dividerColor),
                  const SizedBox(height: 16),

                  // Info Metadata Grid (Reference details grid)
                  _buildDetailRow(
                    context,
                    label: 'Order Type:',
                    valueWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.orderType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    context,
                    label: 'Delivery Time:',
                    value: '${order.branch.deliveryTime} (${order.branch.name})',
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    context,
                    label: 'Payment Type:',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.paymentMethod.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Paid',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    context,
                    label: 'Order Collected:',
                    value: _currentStatus == 'delivered' ? 'Yes' : 'No',
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    context,
                    label: 'Cutlery:',
                    value: 'Included upon request',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Customer Information Card (Reference Design Middle Section)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: primaryColor.withOpacity(0.15),
                        child: Text(
                          order.customerName.isNotEmpty
                              ? order.customerName[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              order.customerName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        order.phone.isNotEmpty ? order.phone : 'Not specified',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.address.isNotEmpty ? order.address : 'Dine-In / Counter Pickup',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Order Summary Heading & Product Items List (Reference Design Right Side)
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail with Quantity Badge (Reference Design)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 68,
                              height: 68,
                              color: primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.fastfood_rounded,
                                color: primaryColor,
                                size: 30,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            left: -4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E293B),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Item Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatDH(item.totalPrice),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Portion: Standard Meal',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            if (item.selectedExtras.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Extras: ${item.selectedExtras.map((e) => '${e.name} (${CurrencyFormatter.formatDH(e.price)})').join(', ')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Financial Summary Breakdown Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(context, 'Subtotal', CurrencyFormatter.formatDH(order.subtotal)),
                  const SizedBox(height: 8),
                  _buildSummaryRow(context, 'Delivery Fee', CurrencyFormatter.formatDH(order.deliveryFee)),
                  if (order.discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(context, 'Discount', '-${CurrencyFormatter.formatDH(order.discount)}', isDiscount: true),
                  ],
                  const SizedBox(height: 12),
                  Divider(height: 1, color: theme.dividerColor),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    context,
                    'Total Amount',
                    CurrencyFormatter.formatDH(order.totalAmount),
                    isTotal: true,
                  ),
                ],
              ),
            ),

            if (order.notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note_alt_outlined, size: 16, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Customer Order Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.notes,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 100), // Bottom padding for sticky actions
          ],
        ),
      ),

      // 4. Sticky Bottom Actions Bar (Reference Layout)
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E26) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Next Status Action Pill Button
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: widget.isUpdating
                        ? null
                        : () async {
                            final nextStatus = _getNextStatus(_currentStatus);
                            if (nextStatus != null) {
                              setState(() {
                                _currentStatus = nextStatus;
                              });
                              await widget.onUpdateStatus(nextStatus);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getStatusButtonColor(_currentStatus),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: widget.isUpdating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _getNextStatusButtonLabel(_currentStatus),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Print Invoice Pill Button (Reference Design)
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _printInvoice(context),
                    icon: const Icon(Icons.print_rounded, size: 20),
                    label: const Text('Print Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, {required String label, String? value, Widget? valueWidget}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        valueWidget ??
            Text(
              value ?? '',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal
                ? theme.colorScheme.onSurface
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 13,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
            color: isDiscount
                ? Colors.green
                : (isTotal ? theme.colorScheme.primary : theme.colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  String? _getNextStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'preparing';
      case 'preparing':
        return 'delivering';
      case 'delivering':
        return 'delivered';
      default:
        return null;
    }
  }

  String _getNextStatusButtonLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Start Preparing';
      case 'preparing':
        return 'Ready for Delivery';
      case 'delivering':
        return 'Mark Delivered';
      case 'delivered':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Update Status';
    }
  }

  Color _getStatusButtonColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF4CAF50);
      case 'preparing':
        return const Color(0xFF2196F3);
      case 'delivering':
        return const Color(0xFF2E7D32);
      case 'delivered':
        return const Color(0xFF757575);
      default:
        return const Color(0xFF757575);
    }
  }
}
