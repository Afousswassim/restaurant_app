import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/branch.dart';

class QrMenuImageGenerator {
  /// Generates a high-resolution, crisp PNG image of the QR Menu card.
  /// Guaranteeing solid opaque backgrounds, Wassim Food branding, branch info,
  /// QR code, and target URL link.
  static Future<Uint8List?> generateQrMenuPng({
    required Branch branch,
    required String qrLink,
  }) async {
    try {
      const double width = 1200.0;
      const double height = 1600.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

      // 1. Solid Off-white Canvas Background (NO TRANSPARENCY)
      final bgPaint = Paint()..color = const Color(0xFFF8FAFC);
      canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bgPaint);

      const primaryColor = Color(0xFF8D4B38);
      const secondaryColor = Color(0xFF6E392A);
      final city = branch.city.isNotEmpty ? branch.city : 'Casablanca';

      // 2. Top Branch Banner Header (Gradient RRect)
      final heroRRect = RRect.fromLTRBR(50, 50, 1150, 310, const Radius.circular(32));
      final heroPaint = Paint()
        ..shader = const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(heroRRect.outerRect);
      canvas.drawRRect(heroRRect, heroPaint);

      // Hero Cutlery Circle Avatar
      final avatarBgPaint = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(130, 180), 50, avatarBgPaint);

      // Fastfood Cutlery Icon inside Circle
      _drawIcon(canvas, Icons.fastfood_rounded, const Offset(104, 154), 52, primaryColor);

      // Branch Name Text
      _drawText(
        canvas,
        text: branch.name,
        offset: const Offset(210, 125),
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        maxWidth: 680,
      );

      // Branch City & Country
      _drawText(
        canvas,
        text: '$city • Morocco',
        offset: const Offset(210, 192),
        fontSize: 26,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.85),
        maxWidth: 680,
      );

      // Hero Active Badge (Top Right)
      final badgeRRect = RRect.fromLTRBR(920, 145, 1090, 201, const Radius.circular(28));
      final badgeBgPaint = Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.25);
      final badgeBorderPaint = Paint()
        ..color = const Color(0xFF34D399).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(badgeRRect, badgeBgPaint);
      canvas.drawRRect(badgeRRect, badgeBorderPaint);

      // Green Dot inside Badge
      final dotPaint = Paint()..color = const Color(0xFF34D399);
      canvas.drawCircle(const Offset(952, 173), 6, dotPaint);

      _drawText(
        canvas,
        text: 'Active',
        offset: const Offset(970, 158),
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );

      // 3. Main White QR Card Box
      final cardRRect = RRect.fromLTRBR(50, 340, 1150, 1510, const Radius.circular(32));
      final cardPaint = Paint()..color = Colors.white;
      final cardBorderPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(cardRRect, cardPaint);
      canvas.drawRRect(cardRRect, cardBorderPaint);

      // 4. Card Header Mark: QR Icon & Dine-in Menu Title
      _drawIcon(canvas, Icons.qr_code_2_rounded, const Offset(430, 385), 36, primaryColor);
      _drawText(
        canvas,
        text: 'Dine-in Menu QR Code',
        offset: const Offset(480, 388),
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      );

      // 5. Inner White QR Frame Box
      final qrFrameRRect = RRect.fromLTRBR(260, 450, 940, 1130, const Radius.circular(32));
      final qrFramePaint = Paint()..color = Colors.white;
      final qrFrameBorderPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(qrFrameRRect, qrFramePaint);
      canvas.drawRRect(qrFrameRRect, qrFrameBorderPaint);

      // 6. Draw QR Code (BLACK ON SOLID WHITE - NO TRANSPARENCY)
      final qrValidationResult = QrValidator.validate(
        data: qrLink,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );
      if (qrValidationResult.qrCode != null) {
        final painter = QrPainter.withQr(
          qr: qrValidationResult.qrCode!,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF), // SOLID WHITE
          gapless: true,
        );

        canvas.save();
        canvas.translate(300, 490);
        painter.paint(canvas, const Size(600, 600));
        canvas.restore();
      }

      // 7. Instructions Section below QR Frame
      _drawText(
        canvas,
        text: 'SCAN ME TO VIEW MENU',
        offset: const Offset(600, 1165),
        fontSize: 38,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF1E293B),
        textAlign: TextAlign.center,
        centerOffset: true,
      );

      _drawText(
        canvas,
        text: 'Scan with your phone camera to view our full menu & order',
        offset: const Offset(600, 1225),
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF64748B),
        textAlign: TextAlign.center,
        centerOffset: true,
      );

      // 8. Target Link Pill Box
      final linkRRect = RRect.fromLTRBR(120, 1285, 1080, 1375, const Radius.circular(24));
      final linkBgPaint = Paint()..color = const Color(0xFFF1F5F9);
      final linkBorderPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(linkRRect, linkBgPaint);
      canvas.drawRRect(linkRRect, linkBorderPaint);

      _drawIcon(canvas, Icons.link_rounded, const Offset(150, 1312), 36, primaryColor);

      _drawText(
        canvas,
        text: qrLink,
        offset: const Offset(200, 1315),
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
        maxWidth: 830,
      );

      // 9. Footer Text
      _drawText(
        canvas,
        text: 'Wassim Food • Digital Menu System',
        offset: const Offset(600, 1435),
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF94A3B8),
        textAlign: TextAlign.center,
        centerOffset: true,
      );

      // End Recording and Convert to PNG
      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating QR Menu PNG: $e');
      return null;
    }
  }

  /// Saves the generated QR Menu PNG to a physical file and triggers native sharing/downloading.
  static Future<void> downloadAndShareQrMenu({
    required BuildContext context,
    required Branch branch,
    required String qrLink,
  }) async {
    try {
      final pngBytes = await generateQrMenuPng(branch: branch, qrLink: qrLink);
      if (pngBytes == null || pngBytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate QR Menu image.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Save PNG file to temporary directory with clean filename
      final tempDir = await getTemporaryDirectory();
      final slug = branch.slug.isNotEmpty
          ? branch.slug.replaceAll(RegExp(r'[^\w\-]'), '_')
          : 'wassimfood';
      final filePath = '${tempDir.path}/${slug}_qr_menu.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes, flush: true);

      // Trigger Share.shareXFiles with physical file on disk
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: '${slug}_qr_menu.png')],
        text: 'Wassim Food QR Menu for ${branch.name}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Menu PNG generated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading QR Menu PNG: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static void _drawText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.left,
    double? maxWidth,
    bool centerOffset = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: 1,
      ellipsis: '...',
    );

    textPainter.layout(maxWidth: maxWidth ?? double.infinity);

    final drawOffset = centerOffset
        ? Offset(offset.dx - (textPainter.width / 2), offset.dy)
        : offset;

    textPainter.paint(canvas, drawOffset);
  }

  static void _drawIcon(
    Canvas canvas,
    IconData icon,
    Offset offset,
    double size,
    Color color,
  ) {
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily ?? 'MaterialIcons',
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, offset);
  }
}
