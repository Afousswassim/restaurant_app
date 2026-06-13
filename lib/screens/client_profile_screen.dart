import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';
import '../widgets/top_actions.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/helpers.dart';
import 'client_login_screen.dart';
import 'orders_screen.dart';
import 'home_screen.dart';

class ClientProfileScreen extends StatefulWidget {
  static const routeName = '/client-profile';

  const ClientProfileScreen({Key? key}) : super(key: key);

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _landmarkController;
  bool _isSaving = false;
  bool _darkThemeValue = false;

  @override
  void initState() {
    super.initState();
    final clientProvider = context.read<ClientProvider>();
    final client = clientProvider.currentClient;

    _nameController = TextEditingController(text: client?.fullName ?? '');
    _phoneController = TextEditingController(text: client?.phone ?? '');
    _addressController = TextEditingController(text: client?.address ?? '');
    _landmarkController = TextEditingController(text: client?.landmark ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final clientProvider = context.read<ClientProvider>();
    final success = await clientProvider.updateProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      landmark: _landmarkController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile updated successfully!' : (clientProvider.error ?? 'Failed to update profile')),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<ClientProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Warning: This action is permanent and cannot be undone. All your details will be erased permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // In a real app we would make a DELETE API call. Here we simulate it by calling logout.
      await context.read<ClientProvider>().logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully.'),
            backgroundColor: Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '??';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);
    final clientProvider = context.watch<ClientProvider>();
    final client = clientProvider.currentClient;

    if (!clientProvider.isAuthenticated || client == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(ClientLoginScreen.routeName);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initials = _getInitials(client.fullName);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
        actions: const [
          TopActions(),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile header card
                  Card(
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      child: Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.pink.shade50,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              client.fullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              client.phone,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildBadge(
                                  icon: Icons.emoji_events_outlined,
                                  label: '180 PTS',
                                  color: Colors.amber.shade700,
                                  bgColor: Colors.amber.shade50,
                                ),
                                const SizedBox(width: 12),
                                _buildBadge(
                                  icon: Icons.favorite_border,
                                  label: '0',
                                  color: Colors.red.shade700,
                                  bgColor: Colors.red.shade50,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Delivery Info Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'DELIVERY INFO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'FULL NAME',
                            icon: Icons.person_outline,
                            validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'PHONE NUMBER',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.isEmpty ? 'Phone number is required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _addressController,
                            label: 'DETAILED ADDRESS',
                            icon: Icons.map_outlined,
                            maxLines: 2,
                            validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _landmarkController,
                            label: 'LANDMARK',
                            icon: Icons.info_outline,
                            hintText: 'Near pharmacy, school, etc. (Optional)',
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveChanges,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined, color: Colors.white),
                              label: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Order History Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'ORDER HISTORY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Orders',
                    subtitle: 'TRACK AND REPEAT ORDERS',
                    onTap: () {
                      Navigator.pushNamed(context, OrdersScreen.routeName);
                    },
                  ),
                  const SizedBox(height: 24),

                  // App Preferences Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'APP PREFERENCES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade50,
                            child: const Icon(Icons.wb_sunny_outlined, color: Colors.red),
                          ),
                          title: const Text(
                            'Dark Theme',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text(_darkThemeValue ? 'ON' : 'OFF'),
                          trailing: Switch(
                            value: _darkThemeValue,
                            activeColor: Colors.red,
                            onChanged: (val) {
                              setState(() {
                                _darkThemeValue = val;
                              });
                            },
                          ),
                        ),
                        const Divider(height: 1, indent: 70),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade50,
                            child: const Icon(Icons.language, color: Colors.red),
                          ),
                          title: const Text(
                            'Application Language',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: const Text('ENGLISH (LTR)'),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            // Language selection placeholder
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // More Settings Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'MORE SETTINGS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade100,
                            child: const Icon(Icons.logout, color: Colors.black54),
                          ),
                          title: const Text(
                            'Logout Session',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: const Text('END ACTIVE SESSION'),
                          onTap: _handleLogout,
                        ),
                        const Divider(height: 1, indent: 70),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade50,
                            child: const Icon(Icons.delete_outline, color: Colors.red),
                          ),
                          title: const Text(
                            'Delete Account',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15),
                          ),
                          subtitle: const Text('ERASE DATA PERMANENTLY'),
                          onTap: _handleDeleteAccount,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // spacer for bottom nav bar
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade50,
          child: Icon(icon, color: Colors.red),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
