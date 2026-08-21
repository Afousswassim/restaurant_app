import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/customer.dart';
import '../utils/helpers.dart';
import '../widgets/admin_stat_card.dart';
import 'customer_details_screen.dart';

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



  // --- Render Widgets ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final width = MediaQuery.of(context).size.width;

    final totalCount = _customers.length;
    final vipCount = _customers.where((c) => c.status == 'VIP').length;
    final blockedCount = _customers.where((c) => c.status == 'Blocked').length;
    final activeCount = _customers.where((c) => c.status == 'Active').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Premium Hero Header Banner (Consistent with Offers & Categories pages)
        Container(
          width: double.infinity,
          height: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.9),
                primaryColor.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.people_rounded,
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Wassim Food Customers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Wassim Food • Customer Management Directory',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.group_rounded, color: Color(0xFFFFC107), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$totalCount Total Customers',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$vipCount VIP • $blockedCount Blocked • $activeCount Active',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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
        const SizedBox(height: 20),

        // Action Row with "Add Customer"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showCustomerFormDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Customer'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

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
    final totalCount = _customers.length;
    final vipCount = _customers.where((c) => c.status == 'VIP').length;
    final blockedCount = _customers.where((c) => c.status == 'Blocked').length;

    final double totalRevenue = _customers.fold(
      0.0,
      (sum, c) => sum + c.totalSpent,
    );
    final double avgSpend = totalCount > 0 ? (totalRevenue / totalCount) : 0.0;

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
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: theme.dividerColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: theme.dividerColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    final filterButton = Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _showAdvancedFilters 
              ? primaryColor 
              : theme.dividerColor,
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
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 450) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    statusDropdown,
                    const SizedBox(height: 12),
                    sortDropdown,
                  ],
                );
              } else {
                return Row(
                  children: [
                    statusDropdown,
                    const SizedBox(width: 12),
                    Expanded(child: sortDropdown),
                  ],
                );
              }
            },
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

  Future<void> _showCustomerProfileDialog(String customerId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(customerId: customerId),
      ),
    );
    if (result == true) {
      _fetchCustomers();
    }
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
      statusBgColor = Colors.green.withOpacity(0.12);
      statusTextColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    } else if (widget.customer.status == 'Blocked') {
      statusBgColor = Colors.red.withOpacity(0.12);
      statusTextColor = Colors.red;
      statusIcon = Icons.block_flipped;
    } else if (widget.customer.status == 'VIP') {
      statusBgColor = Colors.amber.withOpacity(0.15);
      statusTextColor = Colors.amber.shade900;
      statusIcon = Icons.star_rounded;
    } else {
      statusBgColor = Colors.grey.withOpacity(0.12);
      statusTextColor = Colors.grey;
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
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered 
                ? primaryColor.withOpacity(0.5) 
                : theme.dividerColor,
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(_isHovered ? 0.08 : 0.03),
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
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
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
