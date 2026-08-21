import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../models/branch.dart';
import '../utils/helpers.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailsScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _data = {};
  bool _hasChanges = false;

  // Filter values for Orders tab
  String _orderStatusFilter = 'All';
  String _orderLocationFilter = 'All';

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
      _showSuccessSnackBar('Customer status updated to $status');
      _hasChanges = true;
      _loadProfileDetails();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _toggleVip(bool currentVip) async {
    try {
      await ApiService.updateCustomerVip(widget.customerId, !currentVip);
      _showSuccessSnackBar(
        !currentVip ? 'Promoted to VIP!' : 'Removed from VIP tier',
      );
      _hasChanges = true;
      _loadProfileDetails();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _modifyRewards(String action, int points) async {
    try {
      await ApiService.updateCustomerRewards(widget.customerId, action, points);
      _showSuccessSnackBar(
        action == 'add'
            ? 'Added $points reward points'
            : 'Loyalty points reset to zero',
      );
      _hasChanges = true;
      _loadProfileDetails();
    } catch (e) {
      _showErrorSnackBar(e.toString());
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
        final sessionId = widget.customerId;
        await ApiService.createOrder(
          sessionId: sessionId,
          customerName: order.customerName,
          phone: order.phone,
          address: order.address,
          branch: order.branch,
          paymentMethod: order.paymentMethod,
          notes: 'Repeated Order from Admin (Original ID: #${order.id.substring(order.id.length - 6).toUpperCase()})',
          clientId: widget.customerId,
        );
        _showSuccessSnackBar('Order repeated successfully');
        _hasChanges = true;
        _loadProfileDetails();
      } catch (e) {
        _showErrorSnackBar(e.toString());
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
          child: SingleChildScrollView(
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
                _showSuccessSnackBar('Notification dispatched successfully');
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
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

  void _addNewOrderPlaceholder(Customer customer) {
    // Show quick dialog to add a placeholder or repeated order
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Order'),
        content: const Text(
          'Do you want to create a new transaction for this customer? We will simulate creating a new delivery order to their address with their default settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Fetch first branch from memory/API or use default branch data
                // In restaurant app, API Service createOrder handles branch
                await ApiService.createOrder(
                  sessionId: customer.id,
                  customerName: customer.name,
                  phone: customer.phone.isNotEmpty ? customer.phone : '0600000000',
                  address: customer.address.isNotEmpty ? customer.address : 'Casablanca Store',
                  branch: Branch(
                    id: 'default_branch_id',
                    slug: 'default_branch_slug',
                    name: 'Main Branch',
                    address: customer.address.isNotEmpty ? customer.address : 'Casablanca Store',
                    deliveryFee: 0,
                    deliveryTime: '30 mins',
                    city: customer.city.isNotEmpty ? customer.city : 'Casablanca',
                    phone: customer.phone.isNotEmpty ? customer.phone : '0600000000',
                  ),
                  paymentMethod: 'Cash',
                  notes: 'Direct Order from Admin Console',
                  clientId: customer.id,
                );
                _showSuccessSnackBar('Order created successfully!');
                _hasChanges = true;
                _loadProfileDetails();
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: const Text('Create Order'),
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Customer Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Customer Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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

    final statusColor = _getStatusColor(customer.status);
    final isVip = customer.status == 'VIP';

    // Filters for Orders tab
    final filteredOrders = orderHistory.where((order) {
      if (_orderStatusFilter != 'All') {
        if (_orderStatusFilter == 'Paid' && !(order.status == 'delivered' || order.paymentMethod.toLowerCase() == 'card')) {
          return false;
        }
        if (_orderStatusFilter == 'Unpaid' && (order.status == 'delivered' || order.paymentMethod.toLowerCase() == 'card')) {
          return false;
        }
        if (_orderStatusFilter == 'Delivered' && order.status != 'delivered') {
          return false;
        }
        if (_orderStatusFilter == 'Cancelled' && order.status != 'cancelled') {
          return false;
        }
      }
      if (_orderLocationFilter != 'All') {
        if (order.branch.name.toLowerCase() != _orderLocationFilter.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();

    // Unique list of branch names for Location filter
    final locationsSet = {'All'};
    for (var o in orderHistory) {
      if (o.branch.name.isNotEmpty) {
        locationsSet.add(o.branch.name);
      }
    }
    final locationsList = locationsSet.toList();

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            'Customer Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          shape: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
          actions: [
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
        body: Container(
          color: isDark ? const Color(0xFF121217) : Colors.grey.shade50,
          child: Column(
            children: [
              // Header Card matching reference styling
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar & Name Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name & Badge
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    customer.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
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
                              const SizedBox(height: 6),
                              // Location & Source (with wrap protection)
                              Wrap(
                                spacing: 16,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(
                                        customer.city.isNotEmpty ? customer.city : 'Casablanca',
                                        style: TextStyle(
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.storefront_rounded, size: 15, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Source Online Store',
                                        style: TextStyle(
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // High-fidelity Stats Box (Order Value / Total Orders)
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

              // TabBar matching styling rules
              Container(
                color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey.shade500,
                  indicatorColor: primaryColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    const Tab(text: 'Information'),
                    Tab(text: 'Order(${orderHistory.length})'),
                    const Tab(text: 'Wishlist(0)'),
                    const Tab(text: 'Review(0)'),
                  ],
                ),
              ),

              // TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInformationTab(customer, statistics, rewardSystem, favoriteProducts, isDark, primaryColor),
                    _buildOrdersTab(customer, filteredOrders, locationsList, isDark, theme),
                    _buildPlaceholderTab('Wishlist', 'No wishlist items available for this customer.', Icons.favorite_border_rounded),
                    _buildPlaceholderTab('Reviews', 'No product reviews submitted by this customer.', Icons.rate_review_outlined),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Tab View Builders ---

  Widget _buildInformationTab(
    Customer customer,
    Map<String, dynamic> stats,
    Map<String, dynamic> rewards,
    List<dynamic> favorites,
    bool isDark,
    Color primaryColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shipping Address Card with Edit
          _buildShippingCard(customer, isDark),
          const SizedBox(height: 16),
          // Contact Info Bubble Card
          _buildContactCard(customer, isDark),
          const SizedBox(height: 16),
          // Category Section (to match reference design)
          _buildDetailCard(
            title: 'Category',
            action: TextButton(
              onPressed: () => _showEditProfileDialog(customer),
              child: const Text('+ Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            content: Row(
              children: [
                Icon(Icons.grid_view_rounded, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  customer.favoriteCategory.isNotEmpty
                      ? customer.favoriteCategory
                      : 'Add Category',
                  style: TextStyle(
                    fontSize: 13,
                    color: customer.favoriteCategory.isNotEmpty ? null : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Note Section
          _buildDetailCard(
            title: 'Note',
            action: TextButton(
              onPressed: () => _showEditProfileDialog(customer),
              child: const Text('+ Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            content: Row(
              children: [
                Icon(Icons.description_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  'No Note',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Activity statistics
          _buildActivityStatsCard(stats, customer, isDark),
          const SizedBox(height: 16),
          // Loyalty rewards
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
          // Visual map pin placeholder matching reference map visual
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121217) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Abstract Grid Map Background
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                        ),
                        itemBuilder: (c, i) => Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.deepOrange.shade600, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Map View Location',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
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
      content: LayoutBuilder(
        builder: (context, constraints) {
          // If constraints allow side-by-side, render side-by-side
          final isWide = constraints.maxWidth > 500;
          final emailBox = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.blue.shade100,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: isDark ? Colors.blue.shade300 : Colors.blue.shade600),
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
          );

          final phoneBox = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.blue.shade100,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: isDark ? Colors.blue.shade300 : Colors.blue.shade600),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customer.phone.isNotEmpty ? customer.phone : 'No phone number',
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
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: emailBox),
                const SizedBox(width: 12),
                Expanded(child: phoneBox),
              ],
            );
          } else {
            return Column(
              children: [
                emailBox,
                const SizedBox(height: 10),
                phoneBox,
              ],
            );
          }
        },
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
      action: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          TextButton.icon(
            onPressed: _showAddPointsDialog,
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text('Add Points', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
          ),
          TextButton.icon(
            onPressed: () => _modifyRewards('reset', 0),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Reset', style: TextStyle(fontSize: 12, color: Colors.red)),
            style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.rewardName.isNotEmpty ? reward.rewardName : 'Redemption Claim',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reward.notes.isNotEmpty ? reward.notes : 'Points redemption order',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
          // Responsive header row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
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

  // --- Orders Tab View Builder ---

  Widget _buildOrdersTab(
    Customer customer,
    List<Order> orders,
    List<String> locations,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // Dropdown Filters Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E26) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              ),
            ),
          ),
          child: Row(
            children: [
              // Status Dropdown Filter
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _orderStatusFilter,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                      ),
                    ),
                    items: ['All', 'Paid', 'Unpaid', 'Delivered', 'Cancelled'].map((s) {
                      return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _orderStatusFilter = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Location Dropdown Filter
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _orderLocationFilter,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                      ),
                    ),
                    items: locations.map((loc) {
                      return DropdownMenuItem(value: loc, child: Text(loc, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _orderLocationFilter = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Total Order Summary row
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Text(
                'Total order',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  orders.length.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable List of Orders
        Expanded(
          child: orders.isEmpty
              ? Center(
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
                        'No matching transactions found.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildOrderCard(orders[index], isDark, theme);
                  },
                ),
        ),

        // Add order orange button matching reference layout
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E26) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _addNewOrderPlaceholder(customer),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Add order',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order, bool isDark, ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;
    final isDelivered = order.status == 'delivered';
    final isCancelled = order.status == 'cancelled';

    Color statusColor = Colors.orange;
    if (isDelivered) {
      statusColor = Colors.green;
    } else if (isCancelled) {
      statusColor = Colors.red;
    }

    final isPaid = isDelivered || order.paymentMethod.toLowerCase() == 'card';

    final idTruncated = order.id.length > 6
        ? order.id.substring(order.id.length - 6).toUpperCase()
        : order.id.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14.0),
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
          // Row 1: dot indicator + order ID and amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order-$idTruncated',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.formatDH(order.totalAmount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: date on left, branch on right
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
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, thickness: 0.8),
          ),
          // Row 3: status badges and actions, wrapped defensively
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Badges
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              // Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () => _showOrderDetails(order),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => _repeatOrder(order),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildPlaceholderTab(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // --- Profile Edit Form Dialog ---

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
                    value: ['Active', 'Inactive', 'VIP', 'Blocked'].contains(status) ? status : 'Active',
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
                _showSuccessSnackBar('Customer profile updated');
                Navigator.of(context).pop();
                _hasChanges = true;
                _loadProfileDetails();
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
}
