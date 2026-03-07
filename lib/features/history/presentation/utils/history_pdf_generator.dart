// lib/features/history/utils/history_pdf_generator.dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

class HistoryPdfGenerator {
  static Future<File> generateHistoryPdf({
    required List<Map<String, dynamic>> onDeviceScans,
    required List<Map<String, dynamic>> advancedScans,
  }) async {
    final pdf = pw.Document();

    // Statistics
    final totalScans = onDeviceScans.length + advancedScans.length;
    final healthyScans = _countHealthyScans(onDeviceScans, advancedScans);
    final diseasedScans = totalScans - healthyScans;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // HEADER
          _buildProfessionalHeader(),
          pw.SizedBox(height: 30),

          // TITLE BANNER
          _buildTitleBanner(totalScans),
          pw.SizedBox(height: 30),

          // STATISTICS CARDS
          _buildStatisticsRow(
            totalScans: totalScans,
            onDeviceCount: onDeviceScans.length,
            advancedCount: advancedScans.length,
            healthyCount: healthyScans,
            diseasedCount: diseasedScans,
          ),
          pw.SizedBox(height: 35),

          // ON-DEVICE SCANS SECTION
          if (onDeviceScans.isNotEmpty) ...[
            _buildSectionHeader(
              'On-Device AI Scans',
              const PdfColor.fromInt(0xFF1976D2), // Dark blue
              onDeviceScans.length,
            ),
            pw.SizedBox(height: 15),
            ..._buildScanCards(onDeviceScans, 'ondevice'),
            pw.SizedBox(height: 30),
          ],

          // ADVANCED SCANS SECTION
          if (advancedScans.isNotEmpty) ...[
            _buildSectionHeader(
              'Advanced AI Scans',
              const PdfColor.fromInt(0xFF7B1FA2), // Deep purple
              advancedScans.length,
            ),
            pw.SizedBox(height: 15),
            ..._buildScanCards(advancedScans, 'advanced'),
          ],

          // NOTE
          pw.SizedBox(height: 30),
          _buildFooterNote(),

          pw.SizedBox(height: 30),

          // FOOTER
          _buildFooter(totalScans),
        ],
      ),
    );

    return await _savePdf(pdf);
  }

  // Build scan cards in a grid-like layout to prevent overflow
  static List<pw.Widget> _buildScanCards(
      List<Map<String, dynamic>> scans,
      String type,
      ) {
    final List<pw.Widget> cards = [];
    final accentColor = type == 'ondevice'
        ? const PdfColor.fromInt(0xFF1976D2)
        : const PdfColor.fromInt(0xFF7B1FA2);
    final bgColor = type == 'ondevice'
        ? const PdfColor.fromInt(0xFFE3F2FD) // Light blue
        : const PdfColor.fromInt(0xFFF3E5F5); // Light purple

    for (var i = 0; i < scans.length; i++) {
      cards.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: _buildScanCard(
            scans[i],
            i + 1,
            accentColor,
            bgColor,
          ),
        ),
      );
    }
    return cards;
  }

  static pw.Widget _buildProfessionalHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFAFAFA),
        border: pw.Border(
          bottom: pw.BorderSide(
            color: const PdfColor.fromInt(0xFF2E7D32), // Dark green
            width: 3,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'AGRIGUARD',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1B5E20), // Dark green
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Complete Scan History Report',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: const PdfColor.fromInt(0xFF616161), // Grey
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF2E7D32), // Dark green
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              'HISTORY',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitleBanner(int totalScans) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFE8F5E9), // Light green
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SCAN HISTORY REPORT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1B5E20), // Dark green
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: const PdfColor.fromInt(0xFF616161),
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF2E7D32),
              borderRadius: pw.BorderRadius.circular(15),
            ),
            child: pw.Text(
              '$totalScans Total',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatisticsRow({
    required int totalScans,
    required int onDeviceCount,
    required int advancedCount,
    required int healthyCount,
    required int diseasedCount,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 1,
          child: _buildStatCard(
            'TOTAL',
            totalScans.toString(),
            const PdfColor.fromInt(0xFF1976D2),
            const PdfColor.fromInt(0xFFE3F2FD),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          flex: 1,
          child: _buildStatCard(
            'ON-DEVICE',
            onDeviceCount.toString(),
            const PdfColor.fromInt(0xFF2E7D32),
            const PdfColor.fromInt(0xFFE8F5E9),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          flex: 1,
          child: _buildStatCard(
            'ADVANCED',
            advancedCount.toString(),
            const PdfColor.fromInt(0xFF7B1FA2),
            const PdfColor.fromInt(0xFFF3E5F5),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          flex: 1,
          child: _buildStatCard(
            'HEALTHY',
            healthyCount.toString(),
            const PdfColor.fromInt(0xFF2E7D32),
            const PdfColor.fromInt(0xFFC8E6C9),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          flex: 1,
          child: _buildStatCard(
            'DISEASED',
            diseasedCount.toString(),
            const PdfColor.fromInt(0xFFC62828), // Dark red
            const PdfColor.fromInt(0xFFFFEBEE), // Light red
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatCard(
      String label,
      String value,
      PdfColor accentColor,
      PdfColor bgColor,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionHeader(
      String title,
      PdfColor color,
      int count,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightenColor(color, 0.85),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 20,
                color: color,
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              '$count',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildScanCard(
      Map<String, dynamic> scan,
      int number,
      PdfColor accentColor,
      PdfColor bgColor,
      ) {
    final plantName = scan['plantName']?.toString() ?? 'Unknown Plant';
    final disease = scan['diseaseName']?.toString() ??
        scan['diagnosis']?.toString() ??
        'Unknown';
    final severity = scan['severity']?.toString() ?? 'N/A';
    final confidence = _parseConfidence(scan['confidence']);
    final date = _parseDate(scan['scanDate'] ?? scan['timestamp']);
    final isHealthy = disease.toLowerCase().contains('healthy');

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(
          color: _lightenColor(accentColor, 0.5),
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header Row with Number and Status
          pw.Row(
            children: [
              pw.Container(
                width: 30,
                height: 30,
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '$number',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      plantName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF212121),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      disease,
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: isHealthy
                            ? const PdfColor.fromInt(0xFF2E7D32)
                            : const PdfColor.fromInt(0xFFC62828),
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: isHealthy
                      ? const PdfColor.fromInt(0xFFE8F5E9)
                      : const PdfColor.fromInt(0xFFFFEBEE),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  isHealthy ? 'HEALTHY' : 'DISEASED',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: isHealthy
                        ? const PdfColor.fromInt(0xFF2E7D32)
                        : const PdfColor.fromInt(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // Details Row
          pw.Row(
            children: [
              // Severity
              pw.Expanded(
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Severity: ',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF757575),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: _getSeverityBgColor(severity),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        severity.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _getSeverityColor(severity),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Confidence
              pw.Expanded(
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Confidence: ',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF757575),
                      ),
                    ),
                    pw.Text(
                      '${confidence.toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 8),

          // Date
          pw.Row(
            children: [
              pw.Icon(
                const pw.IconData(0xe192), // calendar icon
                size: 10,
                color: const PdfColor.fromInt(0xFF9E9E9E),
              ),
              pw.SizedBox(width: 4),
              pw.Text(
                date,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: const PdfColor.fromInt(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooterNote() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF8E1), // Light amber
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 20,
            height: 20,
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFA000), // Amber
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                'i',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              'For critical plant health issues, please consult with certified agricultural experts.',
              style: pw.TextStyle(
                fontSize: 9,
                color: const PdfColor.fromInt(0xFF5D4037),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(int totalScans) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColor.fromInt(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'AgriGuard Plant Health Analysis',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF616161),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to open PDF
  static Future<bool> openPdf(File file) async {
    try {
      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      debugPrint('Error opening PDF: $e');
      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  static PdfColor _lightenColor(PdfColor color, double amount) {
    final r = color.red + (1 - color.red) * amount;
    final g = color.green + (1 - color.green) * amount;
    final b = color.blue + (1 - color.blue) * amount;
    return PdfColor(r, g, b);
  }

  static PdfColor _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const PdfColor.fromInt(0xFFB71C1C); // Dark red
      case 'high':
      case 'severe':
        return const PdfColor.fromInt(0xFFC62828); // Red
      case 'medium':
      case 'moderate':
        return const PdfColor.fromInt(0xFFEF6C00); // Orange
      case 'low':
      case 'mild':
        return const PdfColor.fromInt(0xFFF9A825); // Yellow
      default:
        return const PdfColor.fromInt(0xFF757575); // Grey
    }
  }

  static PdfColor _getSeverityBgColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const PdfColor.fromInt(0xFFFFCDD2); // Light red
      case 'high':
      case 'severe':
        return const PdfColor.fromInt(0xFFFFEBEE); // Lighter red
      case 'medium':
      case 'moderate':
        return const PdfColor.fromInt(0xFFFFF3E0); // Light orange
      case 'low':
      case 'mild':
        return const PdfColor.fromInt(0xFFFFF9C4); // Light yellow
      default:
        return const PdfColor.fromInt(0xFFEEEEEE); // Light grey
    }
  }

  static double _parseConfidence(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v.replaceAll('%', ''));
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  static int _countHealthyScans(
      List<Map<String, dynamic>> onDevice,
      List<Map<String, dynamic>> advanced,
      ) {
    int count = 0;
    for (final scan in [...onDevice, ...advanced]) {
      final disease = scan['diseaseName']?.toString() ??
          scan['diagnosis']?.toString() ??
          '';
      if (disease.toLowerCase().contains('healthy')) count++;
    }
    return count;
  }

  static String _parseDate(dynamic timestamp) {
    try {
      DateTime? dt;
      if (timestamp is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        dt = DateTime.tryParse(timestamp);
      } else if (timestamp is DateTime) {
        dt = timestamp;
      }

      if (dt != null) {
        return DateFormat('MMM dd, yyyy - hh:mm a').format(dt);
      }
    } catch (e) {
      debugPrint('Date parse error: $e');
    }
    return 'Unknown date';
  }

  static Future<File> _savePdf(pw.Document pdf) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'AgriGuard_History_$timestamp.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    debugPrint('✅ History PDF saved: ${file.path}');
    return file;
  }
}