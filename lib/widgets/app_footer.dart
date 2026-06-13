import 'package:flutter/material.dart';
import '../utils/helpers.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveUtil.isMobile(size.width);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isMobile) _buildMobileLayout(context) else _buildDesktopLayout(context),
              const Divider(color: Colors.grey, height: 48, thickness: 0.5),
              _buildBottomRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // About Section
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBrandHeader(),
              const SizedBox(height: 12),
              const Text(
                'Fresh food prepared daily with fast delivery in Casablanca.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildContactInfo(),
            ],
          ),
        ),
        const SizedBox(width: 40),

        // Branches Section
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Our Branches'),
              _buildBranchText('Maarif'),
              _buildBranchText('Ain Sebaa'),
              _buildBranchText('Sidi Maarouf'),
            ],
          ),
        ),
        const SizedBox(width: 40),

        // Info Section (replacing Quick Links)
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Opening Hours'),
              const Text(
                'Monday - Sunday\n11:00 - 23:00',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Delivery Areas'),
              const Text(
                'Maarif, Ain Sebaa, Sidi Maarouf',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildBrandHeader(),
        const SizedBox(height: 12),
        const Text(
          'Fresh food prepared daily with fast delivery in Casablanca.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 24),
        _buildContactInfo(center: true),
        const SizedBox(height: 32),
        _buildSectionHeader('Our Branches', center: true),
        Wrap(
          spacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _buildBranchText('Maarif'),
            _buildBranchText('Ain Sebaa'),
            _buildBranchText('Sidi Maarouf'),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('Opening Hours', center: true),
        const Text(
          'Monday - Sunday\n11:00 - 23:00',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Delivery Areas', center: true),
        const Text(
          'Maarif, Ain Sebaa, Sidi Maarouf',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.restaurant_menu, color: Colors.deepOrange, size: 24),
        const SizedBox(width: 8),
        const Text(
          'Wassim Food',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {bool center = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        textAlign: center ? TextAlign.center : TextAlign.start,
      ),
    );
  }

  Widget _buildBranchText(String branchName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        branchName,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }

  Widget _buildContactInfo({bool center = false}) {
    final alignment = center ? MainAxisAlignment.center : MainAxisAlignment.start;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignment,
          children: const [
            Icon(Icons.phone, color: Colors.grey, size: 14),
            SizedBox(width: 8),
            Text(
              '+212 6 00 00 00 00',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: alignment,
          children: const [
            Icon(Icons.email, color: Colors.grey, size: 14),
            SizedBox(width: 8),
            Text(
              'contact@wassimfood.ma',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return const Text(
      '© 2026 Wassim Food. All rights reserved.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey, fontSize: 11),
    );
  }
}
