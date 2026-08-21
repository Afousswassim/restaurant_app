import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../services/api_service.dart';

class AdminOfferFormScreen extends StatefulWidget {
  final MenuItem? editingOffer;

  const AdminOfferFormScreen({Key? key, this.editingOffer}) : super(key: key);

  @override
  State<AdminOfferFormScreen> createState() => _AdminOfferFormScreenState();
}

class _AdminOfferFormScreenState extends State<AdminOfferFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedProductId;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _oldPriceController;
  late TextEditingController _offerPriceController;
  late TextEditingController _labelController;

  late DateTime _startDate;
  late DateTime _expiresAt;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingOffer;

    _titleController = TextEditingController(text: editing?.offerTitle ?? '');
    _descController = TextEditingController(text: editing?.offerDescription ?? '');
    _oldPriceController = TextEditingController(
      text: editing?.oldPrice?.toStringAsFixed(0) ?? (editing != null ? editing.price.toStringAsFixed(0) : ''),
    );
    _offerPriceController = TextEditingController(
      text: editing?.offerPrice?.toStringAsFixed(0) ?? '',
    );
    _labelController = TextEditingController(text: editing?.offerLabel ?? '');

    _startDate = editing?.offerStartDate?.toLocal() ?? DateTime.now();
    _expiresAt = editing?.offerExpiresAt?.toLocal() ?? DateTime.now().add(const Duration(days: 7));
    _isActive = editing?.isOfferActive ?? true;

    final menuProvider = context.read<MenuProvider>();
    final eligible = menuProvider.rawMenuItems
        .where((item) => !item.hasOffer || item.id == editing?.id)
        .toList();

    _selectedProductId = editing?.id ?? (eligible.isNotEmpty ? eligible.first.id : '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _oldPriceController.dispose();
    _offerPriceController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  int get _calculatedDiscount {
    final oldP = double.tryParse(_oldPriceController.text.trim()) ?? 0;
    final newP = double.tryParse(_offerPriceController.text.trim()) ?? 0;
    if (oldP <= 0 || newP <= 0 || newP >= oldP) return 0;
    return (((oldP - newP) / oldP) * 100).round();
  }

  double get _calculatedSavings {
    final oldP = double.tryParse(_oldPriceController.text.trim()) ?? 0;
    final newP = double.tryParse(_offerPriceController.text.trim()) ?? 0;
    if (oldP <= 0 || newP <= 0 || newP >= oldP) return 0;
    return oldP - newP;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _expiresAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _expiresAt = picked;
        }
      });
    }
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final oldPrice = double.tryParse(_oldPriceController.text.trim()) ?? 0;
    final offerPrice = double.tryParse(_offerPriceController.text.trim()) ?? 0;
    final label = _labelController.text.trim();

    if (offerPrice >= oldPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer price must be less than the original price.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.editingOffer == null) {
        await ApiService.createOffer(
          productId: _selectedProductId,
          offerTitle: title,
          offerDescription: description,
          oldPrice: oldPrice,
          offerPrice: offerPrice,
          offerLabel: label.isNotEmpty ? label : null,
          offerStartDate: _startDate,
          offerExpiresAt: _expiresAt,
          isOfferActive: _isActive,
        );
      } else {
        await ApiService.updateOffer(
          productId: widget.editingOffer!.id,
          offerTitle: title,
          offerDescription: description,
          oldPrice: oldPrice,
          offerPrice: offerPrice,
          offerLabel: label.isNotEmpty ? label : null,
          offerStartDate: _startDate,
          offerExpiresAt: _expiresAt,
          isOfferActive: _isActive,
        );
      }

      await context.read<MenuProvider>().loadMenu(null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editingOffer == null ? 'Offer created successfully' : 'Offer updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save offer: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final isEditing = widget.editingOffer != null;

    final menuProvider = context.watch<MenuProvider>();
    final eligibleProducts = menuProvider.rawMenuItems
        .where((item) => !item.hasOffer || item.id == widget.editingOffer?.id)
        .toList();

    final selectedProduct = menuProvider.rawMenuItems.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => eligibleProducts.isNotEmpty ? eligibleProducts.first : menuProvider.rawMenuItems.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Offer' : 'Create Special Offer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Selection Card (or product summary if editing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Target Product',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    if (!isEditing && eligibleProducts.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedProductId,
                        decoration: InputDecoration(
                          labelText: 'Select Product',
                          prefixIcon: const Icon(Icons.fastfood_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: eligibleProducts
                            .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.category}) - ${p.price.toStringAsFixed(0)} DH')))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedProductId = val;
                              final prod = menuProvider.rawMenuItems.firstWhere((p) => p.id == val);
                              _oldPriceController.text = prod.price.toStringAsFixed(0);
                            });
                          }
                        },
                      )
                    else
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: selectedProduct.imageUrl.isNotEmpty
                                  ? Image.network(selectedProduct.imageUrl, fit: BoxFit.cover)
                                  : Container(color: primaryColor.withValues(alpha: 0.1), child: Icon(Icons.fastfood, color: primaryColor)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selectedProduct.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(selectedProduct.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${selectedProduct.price.toStringAsFixed(0)} DH',
                              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Offer Details Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offer Details',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Offer Title (e.g. Weekend Special Deal)',
                        prefixIcon: const Icon(Icons.local_offer_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter offer title' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Short Description',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _labelController,
                      decoration: InputDecoration(
                        labelText: 'Offer Badge Label (e.g. SPECIAL, 20% OFF, HOT DEAL)',
                        prefixIcon: const Icon(Icons.new_releases_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pricing & Discount Section with Live Calculator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pricing & Discount',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (_calculatedDiscount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '-$_calculatedDiscount% OFF',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _oldPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Original Price (DH)',
                              prefixIcon: const Icon(Icons.money_off_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (val) {
                              final p = double.tryParse(val ?? '');
                              if (p == null || p <= 0) return 'Enter valid price';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _offerPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Offer Price (DH)',
                              prefixIcon: const Icon(Icons.attach_money_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (val) {
                              final p = double.tryParse(val ?? '');
                              if (p == null || p <= 0) return 'Enter valid price';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_calculatedSavings > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Customer saves ${_calculatedSavings.toStringAsFixed(0)} DH per order',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Schedule & Status Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule & Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePickerTile(
                            label: 'Start Date',
                            date: _startDate,
                            onTap: () => _pickDate(isStart: true),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDatePickerTile(
                            label: 'Expiration Date',
                            date: _expiresAt,
                            onTap: () => _pickDate(isStart: false),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active Offer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Enable or disable offer visibility immediately', style: TextStyle(fontSize: 12)),
                      value: _isActive,
                      activeColor: primaryColor,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Action Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveOffer,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : (isEditing ? 'Save Offer Changes' : 'Create Offer'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerTile({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final local = date.toLocal();
    final dateStr = '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
