import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/top_actions.dart';
import '../widgets/app_drawer.dart';
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
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile updated successfully!' : (clientProvider.error ?? 'Failed to update profile')),
          backgroundColor: success ? colorScheme.secondary : colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleLogout() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
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
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
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
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
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
          SnackBar(
            content: const Text('Account deleted successfully.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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
    final themeProv = context.watch<ThemeProvider>();

    if (!clientProvider.isAuthenticated || client == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(ClientLoginScreen.routeName);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initials = _getInitials(client.fullName);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: theme.dividerColor),
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
                    shadowColor: colorScheme.onSurface.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: theme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      child: Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                initials,
                                style: textTheme.headlineLarge?.copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              client.fullName,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              client.phone,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildBadge(
                                  icon: Icons.emoji_events_outlined,
                                  label: '${client.loyaltyPoints} PTS',
                                  color: colorScheme.primary,
                                  bgColor: colorScheme.primaryContainer,
                                ),
                                const SizedBox(width: 12),
                                _buildBadge(
                                  icon: Icons.favorite_border,
                                  label: '0',
                                  color: colorScheme.error,
                                  bgColor: colorScheme.errorContainer,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'DELIVERY INFO',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    shadowColor: colorScheme.onSurface.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: theme.cardColor,
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
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(Icons.save_outlined, color: colorScheme.onPrimary),
                              label: Text(
                                'Save Changes',
                                style: textTheme.labelLarge?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'ORDER HISTORY',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'APP PREFERENCES',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    shadowColor: colorScheme.onSurface.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: theme.cardColor,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(Icons.wb_sunny_outlined, color: colorScheme.primary),
                          ),
                          title: Text(
                            'Dark Theme',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            themeProv.isDarkMode ? 'ON' : 'OFF',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          trailing: Switch(
                            value: themeProv.isDarkMode,
                            activeColor: colorScheme.primary,
                            onChanged: (val) {
                              themeProv.setDarkMode(val);
                            },
                          ),
                        ),
                        Divider(height: 1, indent: 70, color: theme.dividerColor),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(Icons.language, color: colorScheme.primary),
                          ),
                          title: Text(
                            'Application Language',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'ENGLISH (LTR)',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                          onTap: () {
                            // Language selection placeholder
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // More Settings Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'MORE SETTINGS',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    shadowColor: colorScheme.onSurface.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: theme.cardColor,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.surfaceVariant,
                            child: Icon(Icons.logout, color: colorScheme.onSurfaceVariant),
                          ),
                          title: Text(
                            'Logout Session',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'END ACTIVE SESSION',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          onTap: _handleLogout,
                        ),
                        Divider(height: 1, indent: 70, color: theme.dividerColor),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.errorContainer,
                            child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
                          ),
                          title: Text(
                            'Delete Account',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'ERASE DATA PERMANENTLY',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 1,
      shadowColor: colorScheme.onSurface.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(
          title,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
