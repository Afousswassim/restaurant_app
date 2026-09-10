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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.03),
            blurRadius: 8,
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
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
      _PieData('Pending', pending, OrderStatusUtil.getStatusColor('pending')),
      _PieData('Preparing', preparing, OrderStatusUtil.getStatusColor('preparing')),
      _PieData('Delivering', delivering, OrderStatusUtil.getStatusColor('delivering')),
      _PieData('Delivered', delivered, OrderStatusUtil.getStatusColor('delivered')),
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
      ..color = Colors.grey.withValues(alpha: 0.08)
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
// 2. Revenue Summary: Bar Chart (Real Dynamic Data)
// -------------------------------------------------------------------
class AdminRevenueBarChart extends StatelessWidget {
  final List<dynamic> orders;

  const AdminRevenueBarChart({
    Key? key,
    required this.orders,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    double totalRevenue = 0.0;
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final Map<String, double> realWeeklyData = {
      'Mon': 0.0,
      'Tue': 0.0,
      'Wed': 0.0,
      'Thu': 0.0,
      'Fri': 0.0,
      'Sat': 0.0,
      'Sun': 0.0,
    };

    for (var order in orders) {
      final status = order.status.toString().toLowerCase().trim();
      if (status == 'cancelled') continue;
      final double amt = (order.totalAmount ?? 0).toDouble();
      totalRevenue += amt;

      final DateTime dt = order.createdAt is DateTime
          ? order.createdAt
          : (DateTime.tryParse(order.createdAt.toString()) ?? DateTime.now());
      final label = dayNames[dt.weekday - 1];
      realWeeklyData[label] = (realWeeklyData[label] ?? 0.0) + amt;
    }

    final maxVal = realWeeklyData.values.isEmpty || realWeeklyData.values.every((v) => v == 0)
        ? 1.0
        : realWeeklyData.values.reduce(math.max);

    return Column(
      children: [
        // Subtitle & Total Header
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
                children: realWeeklyData.entries.map((entry) {
                  final double val = entry.value;
                  final double barHeightPct = maxVal > 0 ? (val / maxVal) : 0;
                  final double barHeight = barHeightPct * barHeightMax;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Tooltip(
                        message: '${entry.key}: ${CurrencyFormatter.formatDH(val)}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: math.max(barHeight, 6.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor.withValues(alpha: 0.7), primaryColor],
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


