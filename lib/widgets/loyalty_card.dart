import 'package:flutter/material.dart';

class LoyaltyCard extends StatelessWidget {
  final int points;
  final VoidCallback onRedeemTap;

  const LoyaltyCard({super.key, required this.points, required this.onRedeemTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Next reward calculations
    int nextMilestone = 300;
    String nextReward = "Free Drink";
    if (points >= 1000) {
      nextMilestone = 1000;
      nextReward = "Max Reward Reached";
    } else if (points >= 500) {
      nextMilestone = 1000;
      nextReward = "Free Meal";
    } else if (points >= 300) {
      nextMilestone = 500;
      nextReward = "Free Burger";
    }

    final progress = (points / nextMilestone).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF3E2723), const Color(0xFF1E100C)]
              : [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? const Color(0x33D84315) : const Color(0xFFFFCC80),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB300),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loyalty Rewards',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$points pts',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Next reward: $nextReward at $nextMilestone pts',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : const Color(0xCC5D4037),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: isDarkMode ? Colors.white12 : Colors.white70,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMilestone(context, '300 pts', 'Free Drink', isDarkMode),
                _buildMilestone(context, '500 pts', 'Free Burger', isDarkMode),
                _buildMilestone(context, '1000 pts', 'Free Meal', isDarkMode),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: points >= 300 ? onRedeemTap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.black87,
                  disabledBackgroundColor: isDarkMode ? Colors.white12 : Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Redeem Rewards',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestone(BuildContext context, String pts, String title, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pts,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFB300),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
