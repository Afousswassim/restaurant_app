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
        hintText: 'Search by name, phone or email...',
        prefixIcon: const Icon(Icons.search_rounded),
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
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E26) : Colors.white,
      ),
    );

    final sortDropdown = DropdownButtonFormField<String>(
      value: _sortBy,
      decoration: InputDecoration(
        labelText: 'Sort by',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E26) : Colors.white,
      ),
      items: [
        'Highest Spending',
        'Most Orders',
        'Newest',
        'Alphabetical',
      ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _sortBy = val;
          });
        }
      },
    );

    final List<String> statuses = ['All', 'Active', 'New', 'VIP', 'Blocked'];
    final filterChips = Wrap(
      spacing: 8,
      children: statuses.map((status) {
        final isSelected = _filterStatus == status;
        return FilterChip(
          selected: isSelected,
          label: Text(status == 'All' ? 'All Customers' : status),
          onSelected: (selected) {
            setState(() {
              _filterStatus = status;
            });
          },
          selectedColor: primaryColor.withOpacity(0.15),
          checkmarkColor: primaryColor,
          labelStyle: TextStyle(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF1E1E26) : Colors.white,
        );
      }).toList(),
    );

    if (screenWidth < 1000) {
      // Mobile / Tablet stacked filters
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchBar,
          const SizedBox(height: 12),
          Row(children: [Expanded(child: sortDropdown)]),
          const SizedBox(height: 12),
          filterChips,
        ],
      );
    }

    // Web / Desktop side-by-side layout
    return Row(
      children: [
        Expanded(flex: 3, child: searchBar),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: filterChips),
        const SizedBox(width: 12),
        Expanded(flex: 1, child: sortDropdown),
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
    final primaryColor = theme.colorScheme.primary;
    final statusColor = _getStatusColor(customer.status);
    final isVip = customer.status == 'VIP';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showCustomerProfileDialog(customer.id),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // auto-adapt to content
              children: [
                // Top: Avatar, Customer Name, Email, Phone, City, Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: primaryColor.withOpacity(0.12),
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
                                fontSize: 18,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  customer.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  customer.status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  customer.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  customer.phone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  customer.city.isNotEmpty
                                      ? customer.city
                                      : 'Casablanca',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),

                // Middle: Statistics shown as wrapping chips to prevent overflow
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatChip(
                      icon: Icons.monetization_on_outlined,
                      label: 'Spent',
                      value: CurrencyFormatter.formatDH(customer.totalSpent),
                      color: Colors.purple,
                      isDark: isDark,
                    ),
                    _buildStatChip(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Orders',
                      value: customer.totalOrders.toString(),
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                    _buildStatChip(
                      icon: Icons.stars_rounded,
                      label: 'Points',
                      value: customer.rewardPoints.toString(),
                      color: Colors.amber.shade700,
                      isDark: isDark,
                    ),
                    if (customer.favoriteCategory.isNotEmpty)
                      _buildStatChip(
                        icon: Icons.favorite_outline_rounded,
                        label: 'Likes',
                        value: customer.favoriteCategory,
                        color: primaryColor,
                        isDark: isDark,
                      ),
                    _buildStatChip(
                      icon: Icons.calendar_month_outlined,
                      label: 'Joined',
                      value: _formatSimpleDate(customer.createdAt),
                      color: Colors.green,
                      isDark: isDark,
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),

                // Bottom Actions: Responsive wrapping row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '#${customer.id.length > 5 ? customer.id.substring(customer.id.length - 5).toUpperCase() : customer.id.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      flex: 3,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildActionButton(
                            icon: Icons.remove_red_eye_outlined,
                            tooltip: 'View Profile',
                            color: Colors.blue,
                            isDark: isDark,
                            onPressed: () =>
                                _showCustomerProfileDialog(customer.id),
                          ),
                          _buildActionButton(
                            icon: Icons.edit_outlined,
                            tooltip: 'Edit Profile',
                            color: Colors.green,
                            isDark: isDark,
                            onPressed: () =>
                                _showCustomerFormDialog(customer: customer),
                          ),
                          _buildActionButton(
                            icon: isVip
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            tooltip: isVip ? 'Remove VIP' : 'Make VIP',
                            color: Colors.amber,
                            isDark: isDark,
                            onPressed: () => _toggleVip(customer.id, isVip),
                          ),
                          _buildActionButton(
                            icon: customer.status == 'Blocked'
                                ? Icons.security_rounded
                                : Icons.block_flipped,
                            tooltip: customer.status == 'Blocked'
                                ? 'Unblock Customer'
                                : 'Block Customer',
                            color: customer.status == 'Blocked'
                                ? Colors.teal
                                : Colors.redAccent,
                            isDark: isDark,
                            onPressed: () =>
                                _toggleBlock(customer.id, customer.status),
                          ),
                          _buildActionButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Delete Customer',
                            color: Colors.red,
                            isDark: isDark,
                            onPressed: () => _deleteCustomer(customer.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161D) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16161D) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(icon, size: 16, color: color),
            ),
          ),
        ),
      ),
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
    _tabController = TabController(length: 4, vsync: this);
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: size.width * 0.85,
        height: size.height * 0.85,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16161D) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Modal Header: Banner & Avatar Info
            Container(
              padding: const EdgeInsets.all(24),
              color: isDark ? const Color(0xFF1E1E26) : Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: primaryColor.withOpacity(0.12),
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
                              fontSize: 24,
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
                            Text(
                              customer.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                customer.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customer.city.isNotEmpty
                                  ? customer.city
                                  : 'Casablanca',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Joined: ${widget.formatSimpleDate(customer.createdAt)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Quick control panel actions in header
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _showSendNotificationDialog,
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Send Notification'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _toggleVip(isVip),
                        icon: Icon(
                          isVip
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 16,
                          color: isVip ? Colors.amber.shade800 : null,
                        ),
                        label: Text(isVip ? 'Remove VIP' : 'Make VIP'),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'Active' ||
                              val == 'Inactive' ||
                              val == 'Blocked') {
                            _changeStatus(val);
                          } else if (val == 'reset') {
                            _modifyRewards('reset', 0);
                          }
                        },
                        itemBuilder: (context) => [
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
                            child: Text('Block Customer'),
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
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.more_vert_rounded, size: 20),
                        ),
                      ),
                    ],
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
                    icon: Icon(Icons.info_outline_rounded),
                    text: 'Information',
                  ),
                  Tab(
                    icon: const Icon(Icons.receipt_long_rounded),
                    text: 'Orders (${orderHistory.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.stars_rounded),
                    text: 'Rewards & Tier (${rewardSystem['rewardLevel']})',
                  ),
                  const Tab(
                    icon: Icon(Icons.favorite_outline_rounded),
                    text: 'Favorite Products',
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(customer, statistics, isDark),
                    _buildOrdersTab(orderHistory, isDark),
                    _buildRewardsTab(rewardSystem, isDark),
                    _buildFavoritesTab(favoriteProducts, isDark, primaryColor),
                  ],
                ),
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
    bool isDark,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Full Name', customer.name),
                      _buildInfoRow('Email Address', customer.email),
                      _buildInfoRow('Phone Number', customer.phone),
                      _buildInfoRow(
                        'Address',
                        customer.address.isNotEmpty
                            ? customer.address
                            : 'Not Provided',
                      ),
                      _buildInfoRow(
                        'City',
                        customer.city.isNotEmpty
                            ? customer.city
                            : 'Not Provided',
                      ),
                      _buildInfoRow('Account Status', customer.status),
                      _buildInfoRow(
                        'Registration Date',
                        widget.formatSimpleDate(customer.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity Statistics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'Lifetime Spending',
                        CurrencyFormatter.formatDH(
                          stats['lifetimeSpending']?.toDouble() ?? 0.0,
                        ),
                      ),
                      _buildInfoRow(
                        'Average Order Value',
                        CurrencyFormatter.formatDH(
                          stats['averageOrderValue']?.toDouble() ?? 0.0,
                        ),
                      ),
                      _buildInfoRow(
                        'Total Transactions',
                        stats['totalOrders']?.toString() ?? '0',
                      ),
                      _buildInfoRow(
                        'Completed Orders',
                        stats['completedOrders']?.toString() ?? '0',
                      ),
                      _buildInfoRow(
                        'Cancelled Orders',
                        stats['cancelledOrders']?.toString() ?? '0',
                      ),
                      _buildInfoRow(
                        'Favorite Category',
                        stats['favoriteCategory']?.toString().isNotEmpty == true
                            ? stats['favoriteCategory']
                            : 'N/A',
                      ),
                      _buildInfoRow(
                        'Most Ordered Item',
                        stats['favoriteProduct']?.toString().isNotEmpty == true
                            ? stats['favoriteProduct']
                            : 'N/A',
                      ),
                      _buildInfoRow(
                        'Last Order Date',
                        widget.formatSimpleDate(
                          DateTime.tryParse(
                            stats['lastOrder']?.toString() ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(List<Order> orders, bool isDark) {
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

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E26) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Order ID')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Items')),
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Payment')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: orders.map((order) {
                      final itemsSummary = order.items
                          .map((e) => '${e.quantity}x ${e.name}')
                          .join(', ');
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '#${order.id.length > 6 ? order.id.substring(order.id.length - 6).toUpperCase() : order.id.toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(widget.formatSimpleDate(order.createdAt)),
                          ),
                          DataCell(
                            SizedBox(
                              width: 250,
                              child: Text(
                                itemsSummary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(CurrencyFormatter.formatDH(order.totalAmount)),
                          ),
                          DataCell(Text(order.paymentMethod.toUpperCase())),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (order.status == 'delivered'
                                            ? Colors.green
                                            : Colors.orange)
                                        .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                order.statusDisplay,
                                style: TextStyle(
                                  color: order.status == 'delivered'
                                      ? Colors.green
                                      : Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => _showOrderDetails(order),
                                  child: const Text('View Details'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _repeatOrder(order),
                                  child: const Text('Repeat Order'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsTab(Map<String, dynamic> rewards, bool isDark) {
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.stars_rounded,
                          color: levelColor,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reward Tier Level: $level',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current Loyalty balance: $points Points',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rewards adjustments actions
                      FilledButton.icon(
                        onPressed: _showAddPointsDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Points'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _modifyRewards('reset', 0),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reset Points'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Redeemed Rewards',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (redeemed.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'No rewards redeemed by this client yet.',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: redeemed.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final rewardOrder = redeemed[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.card_giftcard_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rewardOrder.rewardName.isNotEmpty
                                    ? rewardOrder.rewardName
                                    : 'Redemption Claim',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rewardOrder.notes.isNotEmpty
                                    ? rewardOrder.notes
                                    : 'Points redemption order',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        widget.formatSimpleDate(rewardOrder.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(
    List<dynamic> products,
    bool isDark,
    Color primaryColor,
  ) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No products ordered frequently by this customer.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        int crossAxisCount = (maxWidth / 180).ceil();
        if (crossAxisCount < 1) crossAxisCount = 1;
        
        final double spacing = 16.0;
        final double itemWidth = (maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(products.length, (index) {
            final prod = products[index] as Map<String, dynamic>;
            final String name = prod['name'] ?? '';
            final int qty = prod['quantity'] ?? 0;
            final String img = prod['imageUrl'] ?? '';

            return SizedBox(
              width: itemWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: img.isNotEmpty
                            ? Image.network(img, fit: BoxFit.cover)
                            : Icon(
                                Icons.fastfood_rounded,
                                color: Colors.grey.shade400,
                                size: 36,
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ordered $qty times',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
