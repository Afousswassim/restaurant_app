import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CouponCard extends StatelessWidget {
  final String code;
  final String description;

  const CouponCard({super.key, required this.code, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: 94,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF8D4B38).withValues(alpha: 0.18)
                              : const Color(0xFFF9EFEA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF8D4B38).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF8D4B38),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(1, 90),
                painter: _DashedLinePainter(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coupon copied!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.deepOrange,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Container(
                  width: 90,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy_all, color: Colors.deepOrange, size: 20),
                      SizedBox(height: 4),
                      Text(
                        'Copy Code',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: -8,
            right: 82,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -8,
            right: 82,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 8.0;
    final endY = size.height - 8.0;

    while (startY < endY) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
