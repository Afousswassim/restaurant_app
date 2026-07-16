import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../utils/helpers.dart';
import '../widgets/admin_stat_card.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({Key? key}) : super(key: key);

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  String _filterStatus = 'All'; // All, Active, New, VIP, Blocked
  String _sortBy =
      'Highest Spending'; // Highest Spending, Most Orders, Newest, Alphabetical
  List<Customer> _customers = [];
  bool _showAdvancedFilters = false;


  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final customers = await ApiService.getAdminCustomers();
      setState(() {
        _customers = customers;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Actions ---

  Future<void> _toggleVip(String customerId, bool currentVip) async {
    try {
      await ApiService.updateCustomerVip(customerId, !currentVip);
      _fetchCustomers();
      _showSuccessSnackBar(
        currentVip
            ? 'Removed customer from VIP tier'
            : 'Customer is now a VIP!',
      );
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _toggleBlock(String customerId, String currentStatus) async {
    final nextStatus = currentStatus == 'Blocked' ? 'Active' : 'Blocked';
    try {
      await ApiService.updateCustomerStatus(customerId, nextStatus);
      _fetchCustomers();
      _showSuccessSnackBar(
        nextStatus == 'Blocked'
            ? 'Customer account blocked'
            : 'Customer account unblocked',
      );
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _deleteCustomer(String customerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text(
          'Are you sure you want to permanently delete this customer? This action cannot be undone and will remove all their profile data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteCustomer(customerId);
        _fetchCustomers();
        _showSuccessSnackBar('Customer deleted successfully');
      } catch (e) {
        _showErrorSnackBar(e.toString());
      }
    }
  }

  // --- Filtering & Sorting ---

  List<Customer> get _filteredAndSortedCustomers {
    final query = _searchQuery.trim().toLowerCase();
    final now = DateTime.now();

    final filtered = _customers.where((customer) {
      // 1. Status Filter
      if (_filterStatus == 'Active' && customer.status != 'Active')
        return false;
      if (_filterStatus == 'VIP' && customer.status != 'VIP') return false;
      if (_filterStatus == 'Blocked' && customer.status != 'Blocked')
        return false;
      if (_filterStatus == 'New') {
        if (customer.createdAt == null) return false;
        final cDate = customer.createdAt!;
        if (cDate.year != now.year || cDate.month != now.month) return false;
      }

      // 2. Search Query
      if (query.isEmpty) return true;
      final name = customer.name.toLowerCase();
      final email = customer.email.toLowerCase();
      final phone = customer.phone.toLowerCase();
      final city = customer.city.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          city.contains(query);
    }).toList();

    // 3. Sorting
    switch (_sortBy) {
      case 'Highest Spending':
        filtered.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
        break;
      case 'Most Orders':
        filtered.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
        break;
      case 'Newest':
        filtered.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case 'Alphabetical':
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return filtered;
  }

  // --- Helpers ---

  String _formatSimpleDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showSuccessSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String err) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err.replaceAll('Exception: ', '')),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'VIP':
        return Colors.amber.shade700;
      case 'Blocked':
        return Colors.red;
      case 'Inactive':
      default:
        return Colors.grey;
    }
  }

  // --- Render Widgets ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customers',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage registered customers and monitor their restaurant activity.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showCustomerFormDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Customer'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Statistics Overview Grid
        _buildStatsGrid(isDark),
        const SizedBox(height: 24),

        // Filters, Search and Sorting
        _buildFiltersRow(theme, isDark, primaryColor, width),
        const SizedBox(height: 20),

        // Content
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                _error,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.redAccent,
                ),
              ),
            ),
          )
        else if (_filteredAndSortedCustomers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No customers match the current criteria.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _buildCustomerGrid(width, theme, isDark),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    final now = DateTime.now();
    final totalCount = _customers.length;
    final vipCount = _customers.where((c) => c.status == 'VIP').length;
    final blockedCount = _customers.where((c) => c.status == 'Blocked').length;
    final newCount = _customers.where((c) {
      if (c.createdAt == null) return false;
      return c.createdAt!.year == now.year && c.createdAt!.month == now.month;
    }).length;

    final double totalRevenue = _customers.fold(
      0.0,
      (sum, c) => sum + c.totalSpent,
    );
    final double avgSpend = totalCount > 0 ? (totalRevenue / totalCount) : 0.0;

    Customer? mostActive;
    int maxOrders = -1;
    for (var c in _customers) {
      if (c.totalOrders > maxOrders) {
        maxOrders = c.totalOrders;
        mostActive = c;
      }
    }


    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        int crossAxisCount = (maxWidth / 250).ceil();
        if (crossAxisCount < 1) crossAxisCount = 1;
        
        final double spacing = 12.0;
        final double itemWidth = (maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        final children = [
          AdminStatCard(
            title: 'Total Customers',
            value: totalCount.toString(),
            icon: Icons.people_rounded,
            color: Colors.blue,
          ),
          AdminStatCard(
            title: 'New Customers',
            value: newCount.toString(),
            icon: Icons.person_add_rounded,
            color: Colors.green,
            trend: 'This Month',
          ),
          AdminStatCard(
            title: 'VIP Customers',
            value: vipCount.toString(),
            icon: Icons.star_rounded,
            color: Colors.amber.shade700,
          ),
          AdminStatCard(
            title: 'Blocked Customers',
            value: blockedCount.toString(),
            icon: Icons.block_rounded,
            color: Colors.red,
          ),
          AdminStatCard(
            title: 'Average Spending',
            value: CurrencyFormatter.formatDH(avgSpend),
            icon: Icons.monetization_on_rounded,
            color: Colors.purple,
          ),
          AdminStatCard(
            title: 'Most Active',
            value: mostActive != null && mostActive.totalOrders > 0
                ? mostActive.name
                : '-',
            icon: Icons.emoji_events_rounded,
            color: Colors.deepOrange,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _buildFiltersRow(
    ThemeData theme,
    bool isDark,
    Color primaryColor,
    double screenWidth,
  ) {
    final searchBar = TextField(
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search customer...',
        prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E26) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    final filterButton = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _showAdvancedFilters 
              ? primaryColor 
              : (isDark ? Colors.grey.shade900 : Colors.grey.shade200),
          width: _showAdvancedFilters ? 1.5 : 1.0,
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.filter_list_rounded,
          color: _showAdvancedFilters 
              ? primaryColor 
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        tooltip: 'Filters & Sorting',
        onPressed: () {
          setState(() {
            _showAdvancedFilters = !_showAdvancedFilters;
          });
        },
      ),
    );

    final sortDropdown = DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        value: _sortBy,
        decoration: InputDecoration(
          labelText: 'Sort by',
          labelStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            ),
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E26) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        items: [
          'Highest Spending',
          'Most Orders',
          'Newest',
          'Alphabetical',
        ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _sortBy = val;
            });
          }
        },
      ),
    );

    final List<String> statuses = ['All', 'Active', 'New', 'VIP', 'Blocked'];
    
    final statusDropdown = PopupMenuButton<String>(
      onSelected: (status) {
        setState(() {
          _filterStatus = status;
        });
      },
      itemBuilder: (context) => statuses.map((status) {
        final isSelected = _filterStatus == status;
        return PopupMenuItem(
          value: status,
          child: Row(
            children: [
              if (isSelected)
                Icon(Icons.check_rounded, color: primaryColor, size: 18)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(status == 'All' ? 'All Customers' : status),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E26) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _filterStatus == 'All' ? 'Status' : 'Status: $_filterStatus',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: searchBar),
            const SizedBox(width: 12),
            filterButton,
          ],
        ),
        if (_showAdvancedFilters || screenWidth >= 1000) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              statusDropdown,
              const SizedBox(width: 12),
              Expanded(child: sortDropdown),
            ],
          ),
        ],
      ],
    );
  }


  Widget _buildCustomerGrid(double width, ThemeData theme, bool isDark) {
    final filtered = _filteredAndSortedCustomers;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        int cols = 1;
        if (maxWidth > 1200) {
          cols = 3;
        } else if (maxWidth > 800) {
          cols = 2;
        }

        final spacing = 16.0;
        final itemWidth = (maxWidth - (spacing * (cols - 1))) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: filtered.map((customer) {
            return SizedBox(
              width: itemWidth,
              child: _buildCustomerCard(customer, theme, isDark),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCustomerCard(Customer customer, ThemeData theme, bool isDark) {
    return _CustomerCard(
      customer: customer,
      onTap: () => _showCustomerProfileDialog(customer.id),
      onEdit: () => _showCustomerFormDialog(customer: customer),
      onDelete: () => _deleteCustomer(customer.id),
      onToggleVip: () => _toggleVip(customer.id, customer.status == 'VIP'),
      onToggleBlock: () => _toggleBlock(customer.id, customer.status),
      formatSimpleDate: _formatSimpleDate,
    );
  }



  // --- dialogs ---

  void _showCustomerFormDialog({Customer? customer}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer?.name);
    final phoneController = TextEditingController(text: customer?.phone);
    final emailController = TextEditingController(text: customer?.email);
    final passwordController = TextEditingController();
    final addressController = TextEditingController(text: customer?.address);
    final cityController = TextEditingController(text: customer?.city);
    final avatarController = TextEditingController(text: customer?.avatar);
    final pointsController = TextEditingController(
      text: customer?.rewardPoints.toString() ?? '0',
    );
    String status = customer?.status ?? 'Active';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name*'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number*',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter phone' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address*',
                    ),
                    validator: (v) =>
                        v == null || !ValidationUtil.isValidEmail(v)
                        ? 'Enter valid email'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  if (customer == null)
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password*',
                        hintText: 'Default: customer123 if left empty',
                      ),
                    )
                  else
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password (Optional)',
                        hintText: 'Leave blank to keep existing',
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: avatarController,
                    decoration: const InputDecoration(
                      labelText: 'Avatar Image URL',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ['Active', 'Inactive', 'VIP', 'Blocked']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) status = v;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pointsController,
                    decoration: const InputDecoration(
                      labelText: 'Reward Points',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (int.tryParse(v) == null)
                        return 'Must be a valid integer';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final payload = Customer(
                id: customer?.id ?? '',
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim(),
                address: addressController.text.trim(),
                city: cityController.text.trim(),
                avatar: avatarController.text.trim(),
                status: status,
                rewardPoints: int.tryParse(pointsController.text) ?? 0,
                totalOrders: customer?.totalOrders ?? 0,
                totalSpent: customer?.totalSpent ?? 0,
                favoriteCategory: customer?.favoriteCategory ?? '',
                favoriteProduct: customer?.favoriteProduct ?? '',
              );

              try {
                if (customer == null) {
                  await ApiService.createCustomer(
                    payload,
                    passwordController.text.trim(),
                  );
                  _showSuccessSnackBar('Customer created successfully');
                } else {
                  await ApiService.updateCustomer(
                    payload,
                    password: passwordController.text.trim().isEmpty
                        ? null
                        : passwordController.text.trim(),
                  );
                  _showSuccessSnackBar('Customer profile updated');
                }
                Navigator.of(context).pop();
                _fetchCustomers();
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCustomerProfileDialog(String customerId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _CustomerProfileModal(
        customerId: customerId,
        onRefreshParent: _fetchCustomers,
        getStatusColor: _getStatusColor,
        formatSimpleDate: _formatSimpleDate,
        showSuccessSnackBar: _showSuccessSnackBar,
        showErrorSnackBar: _showErrorSnackBar,
      ),
    );
  }
}

// Redesigned customer list card outside _AdminCustomersScreenState
class _CustomerCard extends StatefulWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleVip;
  final VoidCallback onToggleBlock;
  final String Function(DateTime?) formatSimpleDate;

  const _CustomerCard({
    Key? key,
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleVip,
    required this.onToggleBlock,
    required this.formatSimpleDate,
  }) : super(key: key);

  @override
  State<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<_CustomerCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final isVip = widget.customer.status == 'VIP';
    
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;
    
    if (widget.customer.status == 'Active') {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green.shade700;
      statusIcon = Icons.check_circle_rounded;
    } else if (widget.customer.status == 'Blocked') {
      statusBgColor = Colors.red.shade50;
      statusTextColor = Colors.red.shade700;
      statusIcon = Icons.block_flipped;
    } else if (widget.customer.status == 'VIP') {
      statusBgColor = Colors.amber.shade50;
      statusTextColor = Colors.amber.shade800;
      statusIcon = Icons.star_rounded;
    } else {
      statusBgColor = Colors.grey.shade100;
      statusTextColor = Colors.grey.shade600;
      statusIcon = Icons.pause_circle_rounded;
    }

    final subtitleText = widget.customer.email.isNotEmpty 
        ? widget.customer.email 
        : (widget.customer.phone.isNotEmpty ? widget.customer.phone : 'No contact info');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: _isHovered ? (Matrix4.identity()..scale(1.015)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E26) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered 
                ? primaryColor.withOpacity(0.3) 
                : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.06 : 0.02),
              blurRadius: _isHovered ? 12 : 8,
              offset: Offset(0, _isHovered ? 6 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: primaryColor.withOpacity(0.08),
                    backgroundImage: widget.customer.avatar.isNotEmpty
                        ? NetworkImage(widget.customer.avatar)
                        : null,
                    child: widget.customer.avatar.isEmpty
                        ? Text(
                            widget.customer.name.trim().isEmpty
                                ? 'C'
                                : widget.customer.name
                                      .trim()
                                      .split(' ')
                                      .map((p) => p.isEmpty ? '' : p[0])
                                      .take(2)
                                      .join()
                                      .toUpperCase(),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
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
                                widget.customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 12, color: statusTextColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.customer.status,
                                    style: TextStyle(
                                      color: statusTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitleText,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Order Value  ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatDH(widget.customer.totalSpent),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              '  •  Total Order  ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              widget.customer.totalOrders.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                        ),
                        onSelected: (val) {
                          if (val == 'edit') {
                            widget.onEdit();
                          } else if (val == 'vip') {
                            widget.onToggleVip();
                          } else if (val == 'block') {
                            widget.onToggleBlock();
                          } else if (val == 'delete') {
                            widget.onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Profile'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'vip',
                            child: Row(
                              children: [
                                Icon(isVip ? Icons.star_rounded : Icons.star_outline_rounded, size: 18, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(isVip ? 'Remove VIP' : 'Make VIP'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'block',
                            child: Row(
                              children: [
                                Icon(widget.customer.status == 'Blocked' ? Icons.security_rounded : Icons.block_flipped, size: 18, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(widget.customer.status == 'Blocked' ? 'Unblock Customer' : 'Block Customer'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete Customer', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _CustomerProfileModal extends StatefulWidget {
  final String customerId;
  final VoidCallback onRefreshParent;
  final Color Function(String) getStatusColor;
  final String Function(DateTime?) formatSimpleDate;
  final Function(String) showSuccessSnackBar;
  final Function(String) showErrorSnackBar;

  const _CustomerProfileModal({
    Key? key,
    required this.customerId,
    required this.onRefreshParent,
    required this.getStatusColor,
    required this.formatSimpleDate,
    required this.showSuccessSnackBar,
    required this.showErrorSnackBar,
  }) : super(key: key);

  @override
  State<_CustomerProfileModal> createState() => _CustomerProfileModalState();
}

class _CustomerProfileModalState extends State<_CustomerProfileModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final details = await ApiService.getCustomerDetails(widget.customerId);
      setState(() {
        _data = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _changeStatus(String status) async {
    try {
      await ApiService.updateCustomerStatus(widget.customerId, status);
      widget.showSuccessSnackBar('Customer status updated to $status');
      _loadProfileDetails();
      widget.onRefreshParent();
    } catch (e) {
      widget.showErrorSnackBar(e.toString());
    }
  }

  Future<void> _toggleVip(bool currentVip) async {
    try {
      await ApiService.updateCustomerVip(widget.customerId, !currentVip);
      widget.showSuccessSnackBar(
        !currentVip ? 'Promoted to VIP!' : 'Removed from VIP tier',
      );
      _loadProfileDetails();
      widget.onRefreshParent();
    } catch (e) {
      widget.showErrorSnackBar(e.toString());
    }
  }

  Future<void> _modifyRewards(String action, int points) async {
    try {
      await ApiService.updateCustomerRewards(widget.customerId, action, points);
      widget.showSuccessSnackBar(
        action == 'add'
            ? 'Added $points reward points'
            : 'Loyalty points reset to zero',
      );
      _loadProfileDetails();
      widget.onRefreshParent();
    } catch (e) {
      widget.showErrorSnackBar(e.toString());
    }
  }

  Future<void> _repeatOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repeat Order'),
        content: Text(
          'Are you sure you want to duplicate this transaction? A new order will be created under the customer\'s name with the exact same items for a total of ${CurrencyFormatter.formatDH(order.totalAmount)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Repeat'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final sessionId =
            widget.customerId; // simulate/mock sessionId as clientId
        await ApiService.createOrder(
          sessionId: sessionId,
          customerName: order.customerName,
          phone: order.phone,
          address: order.address,
          branch: order.branch,
          paymentMethod: order.paymentMethod,
          notes:
              'Repeated Order from Admin (Original ID: #${order.id.substring(order.id.length - 6).toUpperCase()})',
          clientId: widget.customerId,
        );
        widget.showSuccessSnackBar('Order repeated successfully');
        _loadProfileDetails();
        widget.onRefreshParent();
      } catch (e) {
        widget.showErrorSnackBar(e.toString());
      }
    }
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Order Details #${order.id.substring(order.id.length - 6).toUpperCase()}',
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dine-in/Delivery Branch: ${order.branch.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Delivery Address: ${order.address}'),
              Text('Customer Phone: ${order.phone}'),
              const Divider(height: 24),
              const Text(
                'Ordered Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}x ${item.name}'),
                      Text(
                        CurrencyFormatter.formatDH(item.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text(CurrencyFormatter.formatDH(order.subtotal)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery Fee:'),
                  Text(CurrencyFormatter.formatDH(order.deliveryFee)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount:'),
                  Text('- ${CurrencyFormatter.formatDH(order.discount)}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    CurrencyFormatter.formatDH(order.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddPointsDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Loyalty Points'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Points to add'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final pts = int.tryParse(controller.text);
              if (pts != null && pts > 0) {
                Navigator.of(context).pop();
                _modifyRewards('add', pts);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Push Notification'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title*'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message Body*'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ApiService.sendCustomerNotification(
                  widget.customerId,
                  titleController.text.trim(),
                  messageController.text.trim(),
                );
                Navigator.of(context).pop();
                widget.showSuccessSnackBar(
                  'Notification dispatched successfully',
                );
              } catch (e) {
                widget.showErrorSnackBar(e.toString());
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return const Dialog(
        child: SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error Loading Profile',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 12),
              Text(_error),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadProfileDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final Customer customer = Customer.fromJson(_data['customer']);
    final statistics = _data['statistics'] as Map<String, dynamic>;
    final orderHistory = (_data['orderHistory'] as List)
        .map((o) => Order.fromJson(o))
        .toList();
    final rewardSystem = _data['rewardSystem'] as Map<String, dynamic>;
    final favoriteProducts = _data['favoriteProducts'] as List;

    final statusColor = widget.getStatusColor(customer.status);
    final isVip = customer.status == 'VIP';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: size.height * 0.88,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121217) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header Row: Chevron back and quick actions menu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? const Color(0xFF1E1E26) : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Customer Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    tooltip: 'More Actions',
                    onSelected: (val) {
                      if (val == 'notification') {
                        _showSendNotificationDialog();
                      } else if (val == 'vip') {
                        _toggleVip(isVip);
                      } else if (val == 'edit') {
                        _showEditProfileDialog(customer);
                      } else if (val == 'Active' || val == 'Inactive' || val == 'Blocked') {
                        _changeStatus(val);
                      } else if (val == 'reset') {
                        _modifyRewards('reset', 0);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'notification',
                        child: Row(
                          children: [
                            Icon(Icons.send_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Send Notification'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'vip',
                        child: Row(
                          children: [
                            Icon(isVip ? Icons.star_rounded : Icons.star_outline_rounded, size: 18, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(isVip ? 'Remove VIP' : 'Make VIP'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'Active',
                        child: Text('Activate Account'),
                      ),
                      const PopupMenuItem(
                        value: 'Inactive',
                        child: Text('Deactivate Account'),
                      ),
                      const PopupMenuItem(
                        value: 'Blocked',
                        child: Text('Block Customer', style: TextStyle(color: Colors.red)),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'reset',
                        child: Text(
                          'Reset Loyalty Points',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Profile info card (Name, Avatar, Location, Source)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              color: isDark ? const Color(0xFF1E1E26) : Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: primaryColor.withOpacity(0.08),
                        backgroundImage: customer.avatar.isNotEmpty
                            ? NetworkImage(customer.avatar)
                            : null,
                        child: customer.avatar.isEmpty
                            ? Text(
                                customer.name.trim().isEmpty
                                    ? 'C'
                                    : customer.name
                                          .trim()
                                          .split(' ')
                                          .map((p) => p.isEmpty ? '' : p[0])
                                          .take(2)
                                          .join()
                                          .toUpperCase(),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    customer.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    customer.status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  customer.city.isNotEmpty ? customer.city : 'Casablanca',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.storefront_rounded, size: 15, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  'Source Online Store',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Double card header stats (Order Value & Total Order)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121217) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                CurrencyFormatter.formatDH(customer.totalSpent),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Order Value',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                customer.totalOrders.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Order',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: isDark ? const Color(0xFF1E1E26) : Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: primaryColor,
                tabs: [
                  const Tab(
                    icon: Icon(Icons.info_outline_rounded, size: 20),
                    text: 'Information',
                  ),
                  Tab(
                    icon: const Icon(Icons.receipt_long_rounded, size: 20),
                    text: 'Orders (${orderHistory.length})',
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(customer, statistics, rewardSystem, favoriteProducts, isDark, primaryColor),
                  _buildOrdersTab(orderHistory, isDark, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab(
    Customer customer,
    Map<String, dynamic> stats,
    Map<String, dynamic> rewards,
    List<dynamic> favorites,
    bool isDark,
    Color primaryColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Shipping Address & Contact Info side-by-side or stacked
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 550) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildShippingCard(customer, isDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildContactCard(customer, isDark),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildShippingCard(customer, isDark),
                    const SizedBox(height: 16),
                    _buildContactCard(customer, isDark),
                  ],
                );
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Activity Stats Card
          _buildActivityStatsCard(stats, customer, isDark),
          
          const SizedBox(height: 16),
          
          // Loyalty & Rewards Card
          _buildLoyaltyRewardsCard(rewards, isDark, primaryColor),
          
          const SizedBox(height: 16),
          
          // Frequently Ordered Products
          _buildFavoritesCard(favorites, isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildShippingCard(Customer customer, bool isDark) {
    return _buildDetailCard(
      title: 'Shipping Address',
      action: TextButton(
        onPressed: () => _showEditProfileDialog(customer),
        child: const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            customer.address.isNotEmpty ? customer.address : 'No address provided',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          if (customer.city.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              customer.city,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 10),
          // Simple visual map layout placeholder
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121217) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, color: Colors.grey.shade400, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Visual Address Pin',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Customer customer, bool isDark) {
    return _buildDetailCard(
      title: 'Contact Information',
      action: TextButton(
        onPressed: () => _showEditProfileDialog(customer),
        child: const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Email Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121217) : Colors.blue.shade50.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey.shade900 : Colors.blue.shade100.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customer.email.isNotEmpty ? customer.email : 'No email address',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.blue.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Phone Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121217) : Colors.orange.shade50.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey.shade900 : Colors.orange.shade100.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: isDark ? Colors.orange.shade300 : Colors.orange.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customer.phone.isNotEmpty ? customer.phone : 'No phone number',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStatsCard(Map<String, dynamic> stats, Customer customer, bool isDark) {
    return _buildDetailCard(
      title: 'Activity Statistics',
      content: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 550;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildInfoRow('Average Order Value', CurrencyFormatter.formatDH(stats['averageOrderValue']?.toDouble() ?? 0.0)),
                        _buildInfoRow('Lifetime Spending', CurrencyFormatter.formatDH(stats['lifetimeSpending']?.toDouble() ?? 0.0)),
                        _buildInfoRow('Total Transactions', stats['totalOrders']?.toString() ?? '0'),
                        _buildInfoRow('Completed Orders', stats['completedOrders']?.toString() ?? '0'),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: 24),
                  if (isWide)
                    Expanded(
                      child: Column(
                        children: [
                          _buildInfoRow('Cancelled Orders', stats['cancelledOrders']?.toString() ?? '0'),
                          _buildInfoRow('Favorite Category', stats['favoriteCategory']?.toString().isNotEmpty == true ? stats['favoriteCategory'] : 'N/A'),
                          _buildInfoRow('Registration Date', _formatPrettyDate(customer.createdAt)),
                          _buildInfoRow('Last Order Date', _formatPrettyDate(DateTime.tryParse(stats['lastOrder']?.toString() ?? ''))),
                        ],
                      ),
                    ),
                ],
              ),
              if (!isWide) ...[
                _buildInfoRow('Cancelled Orders', stats['cancelledOrders']?.toString() ?? '0'),
                _buildInfoRow('Favorite Category', stats['favoriteCategory']?.toString().isNotEmpty == true ? stats['favoriteCategory'] : 'N/A'),
                _buildInfoRow('Registration Date', _formatPrettyDate(customer.createdAt)),
                _buildInfoRow('Last Order Date', _formatPrettyDate(DateTime.tryParse(stats['lastOrder']?.toString() ?? ''))),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoyaltyRewardsCard(Map<String, dynamic> rewards, bool isDark, Color primaryColor) {
    final int points = rewards['currentPoints'] ?? 0;
    final String level = rewards['rewardLevel'] ?? 'Silver';
    final redeemed = (rewards['redeemedRewards'] as List)
        .map((o) => Order.fromJson(o))
        .toList();

    Color levelColor = Colors.grey;
    if (level == 'Gold') {
      levelColor = Colors.amber.shade700;
    } else if (level == 'Platinum') {
      levelColor = Colors.blue.shade800;
    }

    return _buildDetailCard(
      title: 'Loyalty & Rewards',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: _showAddPointsDialog,
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text('Add Points', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _modifyRewards('reset', 0),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Reset', style: TextStyle(fontSize: 12, color: Colors.red)),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.stars_rounded, color: levelColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward Tier: $level',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Current Loyalty Balance: $points Points',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (redeemed.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Redeemed Rewards',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: redeemed.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _buildRewardItem(redeemed[index], isDark);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardItem(Order reward, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121217) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.rewardName.isNotEmpty ? reward.rewardName : 'Redemption Claim',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reward.notes.isNotEmpty ? reward.notes : 'Points redemption order',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          Text(
            _formatPrettyDate(reward.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesCard(List<dynamic> products, bool isDark, Color primaryColor) {
    if (products.isEmpty) return const SizedBox.shrink();

    return _buildDetailCard(
      title: 'Frequently Ordered Products',
      content: SizedBox(
        height: 135,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final prod = products[index] as Map<String, dynamic>;
            return _buildFavoriteProductItem(prod, isDark, primaryColor);
          },
        ),
      ),
    );
  }

  Widget _buildFavoriteProductItem(Map<String, dynamic> product, bool isDark, Color primaryColor) {
    final String name = product['name'] ?? '';
    final int qty = product['quantity'] ?? 0;
    final String img = product['imageUrl'] ?? '';

    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121217) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              child: img.isNotEmpty
                  ? Image.network(img, fit: BoxFit.cover)
                  : Icon(
                      Icons.fastfood_rounded,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: $qty times',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required String title, required Widget content, Widget? action}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  letterSpacing: 0.1,
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(List<Order> orders, bool isDark, ThemeData theme) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No orders registered yet for this client.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20.0),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], isDark, theme);
      },
    );
  }

  Widget _buildOrderCard(Order order, bool isDark, ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;
    final isDelivered = order.status == 'delivered';
    final isCancelled = order.status == 'cancelled';
    
    // Status indicators
    Color statusColor = Colors.orange;
    if (isDelivered) {
      statusColor = Colors.green;
    } else if (isCancelled) {
      statusColor = Colors.red;
    }
    
    // Payment status deduction (card is always paid, delivered order is always paid)
    final isPaid = isDelivered || order.paymentMethod.toLowerCase() == 'card';
    
    final idTruncated = order.id.length > 6 
        ? order.id.substring(order.id.length - 6).toUpperCase() 
        : order.id.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Order-#$idTruncated',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatDH(order.totalAmount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Date & Branch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatPrettyDate(order.createdAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              Text(
                order.branch.name,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(height: 1, thickness: 0.8),
          ),
          
          // Badges row and Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badges
              Row(
                children: [
                  // Payment Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPaid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 11,
                          color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPaid ? 'Paid' : 'Unpaid',
                          style: TextStyle(
                            color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Fulfillment/Order Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.statusDisplay,
                      style: TextStyle(
                        color: isCancelled ? Colors.red.shade700 : statusColor.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Actions
              Row(
                children: [
                  TextButton(
                    onPressed: () => _showOrderDetails(order),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _repeatOrder(order),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Repeat Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  String _formatPrettyDate(DateTime? date) {
    if (date == null) return '-';
    final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    try {
      final weekday = weekdays[date.weekday - 1];
      final day = date.day;
      final month = months[date.month - 1];
      final year = date.year;
      return '$weekday $day $month, $year';
    } catch (e) {
      return date.toString().split(' ')[0];
    }
  }

  void _showEditProfileDialog(Customer customer) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final emailController = TextEditingController(text: customer.email);
    final passwordController = TextEditingController();
    final addressController = TextEditingController(text: customer.address);
    final cityController = TextEditingController(text: customer.city);
    final avatarController = TextEditingController(text: customer.avatar);
    final pointsController = TextEditingController(text: customer.rewardPoints.toString());
    String status = customer.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name*'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number*'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email Address*'),
                    validator: (v) => v == null || !ValidationUtil.isValidEmail(v) ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password (Optional)',
                      hintText: 'Leave blank to keep existing',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: avatarController,
                    decoration: const InputDecoration(labelText: 'Avatar Image URL'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ['Active', 'Inactive', 'VIP', 'Blocked']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) status = v;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pointsController,
                    decoration: const InputDecoration(labelText: 'Reward Points'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (int.tryParse(v) == null) return 'Must be a valid integer';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final payload = Customer(
                id: customer.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim(),
                address: addressController.text.trim(),
                city: cityController.text.trim(),
                avatar: avatarController.text.trim(),
                status: status,
                rewardPoints: int.tryParse(pointsController.text) ?? 0,
                totalOrders: customer.totalOrders,
                totalSpent: customer.totalSpent,
                favoriteCategory: customer.favoriteCategory,
                favoriteProduct: customer.favoriteProduct,
              );

              try {
                await ApiService.updateCustomer(
                  payload,
                  password: passwordController.text.trim().isEmpty ? null : passwordController.text.trim(),
                );
                widget.showSuccessSnackBar('Customer profile updated');
                Navigator.of(context).pop();
                _loadProfileDetails();
                widget.onRefreshParent();
              } catch (e) {
                widget.showErrorSnackBar(e.toString());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
