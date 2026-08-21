import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/branch_provider.dart';
import '../providers/menu_provider.dart';
import '../utils/helpers.dart';
import '../widgets/client_navbar.dart';
import '../widgets/branch_card.dart';
import 'home_screen.dart';
import 'admin_login_screen.dart';

class BranchSelectionScreen extends StatefulWidget {
  static const routeName = '/branch-selection';
  const BranchSelectionScreen({Key? key}) : super(key: key);

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<BranchProvider>().loadBranches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);

    return Scaffold(
      appBar: ClientNavbar(
        title: 'Select Branch',
        showMenuButton: false,
        extraActions: [
          Tooltip(
            message: 'Admin Portal',
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).pushNamed(AdminLoginScreen.routeName);
                  },
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 20,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const Icon(
                Icons.location_on_outlined,
                size: 64,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 16),
              Text(
                'Where are we delivering today?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: true ? TextAlign.center : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a branch in Casablanca to browse the menu',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Consumer<BranchProvider>(
                  builder: (context, branchProvider, child) {
                    if (branchProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                        ),
                      );
                    }

                    if (branchProvider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load branches',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => branchProvider.loadBranches(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }

                    final branches = branchProvider.branches;

                    if (branches.isEmpty) {
                      return const Center(
                        child: Text('No branches available.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: branches.length,
                      itemBuilder: (context, index) {
                        final branch = branches[index];
                        return BranchCard(
                          branch: branch,
                          onTap: () {
                            branchProvider.selectBranch(branch);
                            // Load menu for this branch specifically
                            context.read<MenuProvider>().loadMenu(branch.id);
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
