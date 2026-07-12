import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/helpers.dart';

class AdminChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const AdminChartCard({
    Key? key,
    required this.title,
    required this.child,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E1E26),
                ),
              ),
              if (actions != null) Row(children: actions!),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// 1. Orders by Status: Pie/Ring Chart
// -------------------------------------------------------------------
class AdminStatusPieChart extends StatelessWidget {
  final int pending;
  final int preparing;
  final int delivering;
  final int delivered;

  const AdminStatusPieChart({
    Key? key,
    required this.pending,
    required this.preparing,
    required this.delivering,
    required this.delivered,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = pending + preparing + delivering + delivered;
    
    // Fallback if there are no orders yet
    if (total == 0) {
      return Center(
        child: Text(
          'No order data available',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
        ),
      );
    }

    final data = [
      _PieData('Pending', pending, Colors.orange),
      _PieData('Preparing', preparing, Colors.amber.shade700),
      _PieData('Delivering', delivering, Colors.blue),
      _PieData('Delivered', delivered, Colors.green),
    ];

    return Row(
      children: [
        // Ring painter
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _RingPainter(data: data, total: total),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E1E26),
                    ),
                  ),
                  Text(
                    'Orders',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Legend
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((item) {
              final pct = total > 0 ? (item.value / total * 100).toStringAsFixed(0) : '0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PieData {
  final String label;
  final int value;
  final Color color;
  _PieData(this.label, this.value, this.color);
}

class _RingPainter extends CustomPainter {
  final List<_PieData> data;
  final int total;

  _RingPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 14;
    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final Paint bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, 0, 2 * math.pi, false, bgPaint);

    double startAngle = -math.pi / 2;
    for (var item in data) {
      if (item.value == 0) continue;
      final sweepAngle = (item.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -------------------------------------------------------------------
// 2. Revenue Summary: Bar Chart
// -------------------------------------------------------------------
class AdminRevenueBarChart extends StatelessWidget {
  final double totalRevenue;

  const AdminRevenueBarChart({
    Key? key,
    required this.totalRevenue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Simulate revenue distribution over the last 6 days/periods for layout purposes
    final Map<String, double> simulatedData = {
      'Mon': totalRevenue * 0.12 + 150,
      'Tue': totalRevenue * 0.15 + 200,
      'Wed': totalRevenue * 0.08 + 100,
      'Thu': totalRevenue * 0.22 + 300,
      'Fri': totalRevenue * 0.25 + 400,
      'Sat': totalRevenue * 0.18 + 250,
    };

    final maxVal = simulatedData.values.isEmpty
        ? 1.0
        : simulatedData.values.reduce(math.max);

    return Column(
      children: [
        // Subtitle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weekly summary',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
            Text(
              'Total: ${CurrencyFormatter.formatDH(totalRevenue)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Chart bars
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barHeightMax = constraints.maxHeight - 24;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: simulatedData.entries.map((entry) {
                  final double val = entry.value;
                  final double barHeightPct = maxVal > 0 ? (val / maxVal) : 0;
                  final double barHeight = barHeightPct * barHeightMax;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: math.max(barHeight, 6.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor.withOpacity(0.7), primaryColor],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------
// 3. Popular Products: List with Progress Bars
// -------------------------------------------------------------------
class AdminPopularProductsChart extends StatelessWidget {
  const AdminPopularProductsChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E26);
    final captionColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final backgroundColor = isDark ? const Color(0xFF1F1F28) : const Color(0xFFF9F9FB);
    final progressBackground = isDark ? Colors.white12 : const Color(0xFFE8E8EA);

    final popularProducts = [
      {'name': 'Tacos Mixte double', 'category': 'Tacos', 'rating': '4.8', 'percent': 0.85},
      {'name': 'Panini Poulet', 'category': 'Panini', 'rating': '4.6', 'percent': 0.72},
      {'name': 'Pizza Fruits de Mer', 'category': 'Pizza', 'rating': '4.5', 'percent': 0.61},
      {'name': 'Cheeseburger', 'category': 'Burger', 'rating': '4.7', 'percent': 0.53},
      {'name': 'Salade Fraîche Verte', 'category': 'Salads', 'rating': '4.4', 'percent': 0.48},
    ]
      ..sort((a, b) => (b['percent'] as double).compareTo(a['percent'] as double));

    final topProducts = popularProducts.take(5).toList();

    if (topProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            '📦 No popular products available.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: captionColor,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: topProducts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final product = topProducts[index];
          final name = product['name'] as String;
          final category = product['category'] as String;
          final rating = product['rating'] as String;
          final percent = product['percent'] as double;
          final percentLabel = '${(percent * 100).round()}%';

          return SizedBox(
            height: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 11,
                                color: captionColor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(
                                width: constraints.maxWidth,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: progressBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              Container(
                                width: constraints.maxWidth * percent,
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFB96B2D), Color(0xFFE58A2F)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      percentLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: captionColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
