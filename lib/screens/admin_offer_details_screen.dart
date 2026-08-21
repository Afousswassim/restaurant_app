import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';
import 'admin_offer_form_screen.dart';

class AdminOfferDetailsScreen extends StatefulWidget {
  final MenuItem offer;

  const AdminOfferDetailsScreen({Key? key, required this.offer}) : super(key: key);

  @override
  State<AdminOfferDetailsScreen> createState() => _AdminOfferDetailsScreenState();
}

class _AdminOfferDetailsScreenState extends State<AdminOfferDetailsScreen> {
  late MenuItem _currentOffer;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _currentOffer = widget.offer;
  }

  bool get _isExpired {
    final now = DateTime.now();
    return _currentOffer.offerExpiresAt != null && now.isAfter(_currentOffer.offerExpiresAt!);
  }

  bool get _isScheduled {
    final now = DateTime.now();
    return _currentOffer.offerStartDate != null &&
        _currentOffer.offerStartDate!.isAfter(now) &&
        _currentOffer.isOfferActive &&
        !_isExpired;
  }


  String get _statusLabel {
    if (!_currentOffer.isOfferActive) return 'Disabled';
    if (_isExpired) return 'Expired';
    if (_isScheduled) return 'Scheduled';
    return 'Active';
  }

  Color get _statusColor {
    if (!_currentOffer.isOfferActive) return Colors.grey;
    if (_isExpired) return Colors.red;
    if (_isScheduled) return Colors.orange;
    return Colors.green;
  }

  int get _discountPercentage {
    final oldP = _currentOffer.oldPrice ?? 0;
    final newP = _currentOffer.offerPrice ?? _currentOffer.price;
    if (oldP <= 0 || newP >= oldP) return 0;
    return (((oldP - newP) / oldP) * 100).round();
  }

  double get _savingsAmount {
    final oldP = _currentOffer.oldPrice ?? 0;
    final newP = _currentOffer.offerPrice ?? _currentOffer.price;
    if (oldP <= 0 || newP >= oldP) return 0;
    return oldP - newP;
  }

  Future<void> _toggleActive(bool value) async {
    setState(() => _isToggling = true);
    try {
      await ApiService.toggleOffer(productId: _currentOffer.id, isActive: value);
      await context.read<MenuProvider>().loadMenu(null);
      if (mounted) {
        final fresh = context.read<MenuProvider>().rawMenuItems.firstWhere(
              (p) => p.id == _currentOffer.id,
              orElse: () => _currentOffer,
            );
        setState(() {
          _currentOffer = fresh;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Offer activated' : 'Offer disabled'),
            backgroundColor: value ? Colors.green : Colors.grey.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  Future<void> _deleteOffer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Offer', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Delete special offer for "${_currentOffer.name}"? The item will remain in the menu without promotional pricing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Delete Offer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteOffer(_currentOffer.id);
        await context.read<MenuProvider>().loadMenu(null);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offer deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete offer: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer Details', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Offer',
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminOfferFormScreen(editingOffer: _currentOffer),
                ),
              );
              if (updated == true && mounted) {
                final fresh = context.read<MenuProvider>().rawMenuItems.firstWhere(
                      (p) => p.id == _currentOffer.id,
                      orElse: () => _currentOffer,
                    );
                setState(() => _currentOffer = fresh);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Offer',
            onPressed: _deleteOffer,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Product Hero Image Banner
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _currentOffer.imageUrl.isNotEmpty
                        ? Image.network(
                            _currentOffer.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: primaryColor.withValues(alpha: 0.1),
                              child: Icon(Icons.fastfood, size: 64, color: primaryColor),
                            ),
                          )
                        : Container(
                            color: primaryColor.withValues(alpha: 0.1),
                            child: Icon(Icons.fastfood, size: 64, color: primaryColor),
                          ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Status Badge Top Right
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _statusLabel.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Discount badge top left
                    if (_discountPercentage > 0)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$_discountPercentage% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    // Product Title at bottom of banner
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _currentOffer.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currentOffer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Price & Savings Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Promotional Pricing',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Original Price', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            _currentOffer.oldPrice != null
                                ? CurrencyFormatter.formatDH(_currentOffer.oldPrice!)
                                : CurrencyFormatter.formatDH(_currentOffer.price),
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Offer Price', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatDH(
                              _currentOffer.offerPrice ?? _currentOffer.effectivePrice,
                            ),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_savingsAmount > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.savings_outlined, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Customers save ${CurrencyFormatter.formatDH(_savingsAmount)} per item!',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Offer Info & Label Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer_outlined, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _currentOffer.offerTitle?.isNotEmpty == true
                            ? _currentOffer.offerTitle!
                            : 'Special Offer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_currentOffer.offerLabel?.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _currentOffer.offerLabel!,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_currentOffer.offerDescription?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Text(
                      _currentOffer.offerDescription!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Validity Schedule Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offer Validity & Schedule',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Start Date',
                          dateStr: _formatDate(_currentOffer.offerStartDate),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTile(
                          icon: Icons.event_available_outlined,
                          label: 'Expiration Date',
                          dateStr: _formatDate(_currentOffer.offerExpiresAt),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Toggle Switch Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Offer Status',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentOffer.isOfferActive ? 'Active & visible in app' : 'Offer is currently disabled',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  _isToggling
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Switch.adaptive(
                          value: _currentOffer.isOfferActive,
                          activeColor: primaryColor,
                          onChanged: _toggleActive,
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Edit & Delete Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _deleteOffer,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete Offer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminOfferFormScreen(editingOffer: _currentOffer),
                          ),
                        );
                        if (updated == true && mounted) {
                          final fresh = context.read<MenuProvider>().rawMenuItems.firstWhere(
                                (p) => p.id == _currentOffer.id,
                                orElse: () => _currentOffer,
                              );
                          setState(() => _currentOffer = fresh);
                        }
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Offer', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
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

  Widget _buildDateTile({
    required IconData icon,
    required String label,
    required String dateStr,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
