import 'package:flutter/material.dart';

class TopActions extends StatelessWidget {
  const TopActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          child: const Icon(
            Icons.notifications_none,
            color: Colors.black54,
            size: 20,
          ),
          onTap: () {
            // Notifications feature placeholder
          },
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          child: const Icon(
            Icons.dark_mode_outlined,
            color: Colors.black54,
            size: 20,
          ),
          onTap: () {
            // Dark mode toggle placeholder
          },
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          child: const Text(
            'DH',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          onTap: () {
            // Currency view placeholder
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildActionButton({required Widget child, required VoidCallback onTap}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(child: child),
        ),
      ),
    );
  }
}
