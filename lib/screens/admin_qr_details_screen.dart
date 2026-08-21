import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/branch.dart';
import '../utils/helpers.dart';

class AdminQrDetailsScreen extends StatefulWidget {
  final Branch branch;
  final String qrLink;

  const AdminQrDetailsScreen({
    Key? key,
    required this.branch,
    required this.qrLink,
  }) : super(key: key);

  @override
  State<AdminQrDetailsScreen> createState() => _AdminQrDetailsScreenState();
}

class _AdminQrDetailsScreenState extends State<AdminQrDetailsScreen> {
  late String _currentQrLink;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _currentQrLink = widget.qrLink;
  }

  Future<void> _downloadQR() async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: _currentQrLink,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      final qrCode = qrValidationResult.qrCode;
      if (qrCode == null) return;

      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        emptyColor: const Color(0x00FFFFFF),
        gapless: true,
      );

      final picData = await painter.toImageData(2048, format: ui.ImageByteFormat.png);
      if (picData != null) {
        final buffer = picData.buffer.asUint8List();
        await Share.shareXFiles(
          [XFile.fromData(buffer, mimeType: 'image/png', name: '${widget.branch.slug}_qr.png')],
          text: 'Wassim Food QR Menu for ${widget.branch.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating QR: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printQR() async {
    try {
      final doc = pw.Document();

      final qrValidationResult = QrValidator.validate(
        data: _currentQrLink,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      final painter = QrPainter.withQr(
        qr: qrValidationResult.qrCode!,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );
      final picData = await painter.toImageData(1024, format: ui.ImageByteFormat.png);
      final img = pw.MemoryImage(picData!.buffer.asUint8List());

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Wassim Food',
                    style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    widget.branch.name,
                    style: pw.TextStyle(fontSize: 20, color: PdfColors.deepOrange),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    widget.branch.address,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 32),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(16),
                      border: pw.Border.all(color: PdfColors.grey300, width: 2),
                    ),
                    child: pw.Image(img, width: 200, height: 200),
                  ),
                  pw.SizedBox(height: 32),
                  pw.Text(
                    'SCAN ME',
                    style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, letterSpacing: 2),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'To view our full menu and order directly from your phone.',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: '${widget.branch.slug}_qr_menu',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing QR: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareQR() async {
    await Share.share(
      'Scan to view the dine-in menu for Wassim Food ${widget.branch.name}: $_currentQrLink',
      subject: 'Wassim Food QR Menu',
    );
  }

  Future<void> _regenerateQR() async {
    setState(() => _isRegenerating = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final updatedLink = widget.qrLink.contains('?') 
        ? '${widget.qrLink}&v=$timestamp' 
        : '${widget.qrLink}?v=$timestamp';
    
    setState(() {
      _currentQrLink = updatedLink;
      _isRegenerating = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code regenerated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _previewMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E26) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer Menu Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8D4B38).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            size: 48,
                            color: Color(0xFF8D4B38),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Wassim Food - ${widget.branch.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Target URL: $_currentQrLink',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: _currentQrLink));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Menu URL copied! Open in browser to view live menu.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Copy & Open Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8D4B38),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF8D4B38);
    final city = widget.branch.city.isNotEmpty ? widget.branch.city : 'Casablanca';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121217) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E26) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFFFEBE5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: primaryColor,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'QR Menu Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _shareQR,
            icon: Icon(Icons.share_outlined, color: primaryColor),
            tooltip: 'Share QR',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner for Branch
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8D4B38), Color(0xFF6E392A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6E392A).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fastfood_rounded,
                      color: Color(0xFF8D4B38),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.branch.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$city • Morocco',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF34D399).withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircleAvatar(radius: 4, backgroundColor: Color(0xFF34D399)),
                        SizedBox(width: 6),
                        Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Center QR Card
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Brand mark above QR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.qr_code_2_rounded, color: primaryColor, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dine-in Menu QR',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // QR Image Frame
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: _currentQrLink,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            gapless: false,
                          ),
                          if (_isRegenerating)
                            Container(
                              width: 220,
                              height: 220,
                              color: Colors.white.withOpacity(0.85),
                              child: Center(
                                child: CircularProgressIndicator(color: primaryColor),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // URL Link box
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: _currentQrLink));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Menu URL copied to clipboard!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_rounded, size: 16, color: primaryColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _currentQrLink,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.copy_rounded, size: 14, color: Colors.grey.shade500),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Metadata Card (Info: creation date, delivery time, fee, city)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Branch Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile(
                          context,
                          icon: Icons.location_on_outlined,
                          title: 'Address',
                          value: widget.branch.address,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoTile(
                          context,
                          icon: Icons.timer_outlined,
                          title: 'Delivery Time',
                          value: widget.branch.deliveryTime.isNotEmpty ? widget.branch.deliveryTime : '20-30 min',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile(
                          context,
                          icon: Icons.delivery_dining_outlined,
                          title: 'Delivery Fee',
                          value: CurrencyFormatter.formatDH(widget.branch.deliveryFee),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoTile(
                          context,
                          icon: Icons.calendar_today_outlined,
                          title: 'Creation Date',
                          value: '26 July 2026',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons Section
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 14),

            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _printQR,
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('Print A5 QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _downloadQR,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download PNG'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: _currentQrLink));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Link copied to clipboard!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy Link'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                          side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _regenerateQR,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Regenerate QR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                          side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _previewMenu,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Preview Customer Menu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF2A2A36) : const Color(0xFFF1F5F9),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8D4B38)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
