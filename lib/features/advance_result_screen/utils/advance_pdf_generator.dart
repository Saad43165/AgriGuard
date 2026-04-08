// lib/features/ResultScreen/utils/advanced_pdf_generator.dart
//
// ── Zero asset setup required ────────────────────────────────────────────────
// Font loading uses PdfGoogleFonts from the `printing` package, which you
// almost certainly already have (it's the companion package to `pdf`).
//
// pubspec.yaml — just make sure these are present:
//   dependencies:
//     pdf: ^3.x.x
//     printing: ^5.x.x      ← this is what gives us PdfGoogleFonts
//     path_provider: ^2.x.x
//     intl: ^0.x.x
//
// No flutter.assets entries. No TTF files. Nothing else needed.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';   // <-- PdfGoogleFonts lives here
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class AdvancedPdfGenerator {
  // ─── Palette with better contrast ─────────────────────────────────────────
  static const _blue900   = PdfColor(0.0, 0.4, 0.8);      // Dark blue for text
  static const _blue700   = PdfColor(0.1, 0.5, 0.9);      // Medium blue
  static const _blue500   = PdfColor(0.2, 0.6, 1.0);      // Bright blue
  static const _blue300   = PdfColor(0.6, 0.8, 1.0);      // Light blue
  static const _blue100   = PdfColor(0.9, 0.95, 1.0);     // Very light blue
  static const _blueGrey  = PdfColor(0.4, 0.5, 0.6);
  static const _grey100   = PdfColor(0.98, 0.98, 0.98);   // Near white
  static const _grey300   = PdfColor(0.9, 0.9, 0.9);      // Light grey
  static const _grey600   = PdfColor(0.5, 0.5, 0.5);      // Medium grey
  static const _textDark  = PdfColor(0.1, 0.1, 0.1);      // Almost black

  // Status colors
  static const _green700  = PdfColor(0.0, 0.5, 0.0);      // Dark green
  static const _green100  = PdfColor(0.9, 1.0, 0.9);      // Light green
  static const _red700    = PdfColor(0.8, 0.0, 0.0);      // Dark red
  static const _red100    = PdfColor(1.0, 0.9, 0.9);      // Light red
  static const _amber700  = PdfColor(0.9, 0.5, 0.0);      // Dark amber
  static const _amber100  = PdfColor(1.0, 0.95, 0.8);     // Light amber
  static const _amberAcc  = PdfColor(1.0, 0.8, 0.0);      // Bright amber
  static const _purple400 = PdfColor(0.6, 0.3, 0.8);      // Medium purple
  static const _purple100 = PdfColor(0.95, 0.9, 1.0);     // Light purple
  static const _purpleBdr = PdfColor(0.8, 0.6, 0.9);      // Purple border

  // ─── Font cache ────────────────────────────────────────────────────────────
  static pw.Font? _regular;
  static pw.Font? _bold;
  static pw.Font? _italic;

  /// Load fonts using PdfGoogleFonts
  static Future<void> _loadFonts() async {
    if (_regular != null) return;
    _regular = await PdfGoogleFonts.notoSansRegular();
    _bold    = await PdfGoogleFonts.notoSansBold();
    _italic  = await PdfGoogleFonts.notoSansItalic();
  }

  /// Central text-style factory
  static pw.TextStyle _ts({
    double fontSize = 10,
    PdfColor color = _textDark,
    bool bold = false,
    bool italic = false,
    double? letterSpacing,
    double? height,
  }) {
    return pw.TextStyle(
      font:          bold ? _bold : (italic ? _italic : _regular),
      fontBold:      _bold,
      fontItalic:    _italic,
      fontSize:      fontSize,
      color:         color,
      letterSpacing: letterSpacing,
      lineSpacing:   height != null ? (height - 1) * fontSize : null,
    );
  }

  // ─── Entry point ───────────────────────────────────────────────────────────
  static Future<File> generatePdf({
    required Map<String, dynamic> analysisResult,
    required Map<String, dynamic> originalScanData,
    Uint8List? plantImageBytes,
  }) async {
    await _loadFonts();

    final pdf    = pw.Document();
    final data   = analysisResult['data'] as Map<String, dynamic>? ?? {};
    final source = analysisResult['source']?.toString() ?? 'Advanced AI';

    final plantName      = data['plantName']?.toString()   ?? 'Unknown Plant';
    final diagnosis      = data['diseaseName']?.toString() ?? 'Unknown';
    final confidence     = _parseConfidence(data['confidence']);
    final severity       = data['severity']?.toString()    ?? 'Unknown';
    final symptoms       = _parseList(data['symptoms']);
    final remediation    = _parseList(data['remediation']);
    final precautions    = _parseList(data['precautions']);
    final additionalInfo = data['additionalInfo']?.toString() ?? '';
    final scanDate       = DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now());
    final isHealthy      = diagnosis.toLowerCase().contains('healthy');
    final severityColor  = _getSeverityColor(severity);
    final statusColor    = isHealthy ? _green700 : _amber700;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base:   _regular!,
          bold:   _bold!,
          italic: _italic!,
        ),
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPageHeader(),
        footer: (context) => _buildPageFooter(context),
        build: (context) => [
          // Header Section - Always starts on new page
          _buildHeader(scanDate, source),
          pw.SizedBox(height: 20),

          // Title Banner
          _buildTitleBanner(scanDate, source),
          pw.SizedBox(height: 25),

          // Image Section (if available)
          if (plantImageBytes != null) ...[
            _buildImageSection(plantImageBytes),
            pw.SizedBox(height: 25),
          ],

          // Diagnosis Section
          _buildSectionHeader('Comprehensive Diagnosis', _blue900),
          pw.SizedBox(height: 15),
          _buildDiagnosisRow(plantName, diagnosis, severity, statusColor, severityColor),
          pw.SizedBox(height: 20),

          // Confidence Meter (if available)
          if (confidence > 0) ...[
            _buildConfidenceMeter(confidence),
            pw.SizedBox(height: 20),
          ],

          // Symptoms Section
          if (symptoms.isNotEmpty) ...[
            _buildSectionHeader('Detected Symptoms', _red700),
            pw.SizedBox(height: 10),
            _buildBulletList(symptoms, _red100, _red700),
            pw.SizedBox(height: 20),
          ],

          // Treatment Section
          if (remediation.isNotEmpty) ...[
            _buildSectionHeader('Treatment Protocol', _green700),
            pw.SizedBox(height: 10),
            _buildNumberedList(remediation, _green100, _green700),
            pw.SizedBox(height: 20),
          ],

          // Precautions Section
          if (precautions.isNotEmpty) ...[
            _buildSectionHeader('Preventive Measures', _amber700),
            pw.SizedBox(height: 10),
            _buildBulletList(precautions, _amber100, _amber700),
            pw.SizedBox(height: 20),
          ],

          // Additional Info Section
          if (additionalInfo.isNotEmpty) ...[
            _buildAdditionalInfo(additionalInfo),
            pw.SizedBox(height: 20),
          ],

          // Disclaimer
          _buildDisclaimer(),

          // Add some bottom padding
          pw.SizedBox(height: 20),
        ],
      ),
    );

    return _savePdf(pdf);
  }

  // ─── Page Header ───────────────────────────────────────────────────────
  static pw.Widget _buildPageHeader() {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(bottom: 10, right: 20),
      child: pw.Text(
        'AgriGuard Advanced Analysis',
        style: pw.TextStyle(
          fontSize: 8,
          color: _grey600,
        ),
      ),
    );
  }

  // ─── Page Footer ───────────────────────────────────────────────────────
  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(
          fontSize: 8,
          color: _grey600,
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(String date, String source) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          bottom: pw.BorderSide(color: _blue500, width: 3),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Text(
                    'AGRIGUARD',
                    style: _ts(fontSize: 28, color: _blue900, bold: true, letterSpacing: 1.5),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: _blue500,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'PRO',
                      style: _ts(fontSize: 9, color: PdfColors.white, bold: true),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Advanced Plant Health Analysis',
                style: _ts(fontSize: 10, color: _grey600),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: _blue700,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'REPORT',
              style: _ts(fontSize: 12, color: PdfColors.white, bold: true, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Title Banner ──────────────────────────────────────────────────────
  static pw.Widget _buildTitleBanner(String scanDate, String source) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _blue100,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ANALYSIS REPORT',
                style: _ts(fontSize: 16, color: _blue900, bold: true),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                scanDate,
                style: _ts(fontSize: 9, color: _blueGrey),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _blue700,
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 4,
                  height: 4,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.white,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  _sanitize(source).toUpperCase(),
                  style: _ts(fontSize: 8, color: PdfColors.white, bold: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Image Section ─────────────────────────────────────────────────────
  static pw.Widget _buildImageSection(Uint8List bytes) {
    return pw.Center(
      child: pw.Container(
        width: 350,
        height: 220,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _blue300, width: 2),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 10,
          verticalRadius: 10,
          child: pw.Image(
            pw.MemoryImage(bytes),
            fit: pw.BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // ─── Section Header ────────────────────────────────────────────────────
  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _lighten(color, 0.85),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 18,
            color: color,
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              title.toUpperCase(),
              style: _ts(fontSize: 12, color: color, bold: true, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Diagnosis Row ─────────────────────────────────────────────────────
  static pw.Widget _buildDiagnosisRow(
      String plant,
      String disease,
      String severity,
      PdfColor statusColor,
      PdfColor sevColor,
      ) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 1,
          child: _buildDiagnosisCard('Plant', plant, _blue900, _blue100),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          flex: 1,
          child: _buildDiagnosisCard('Disease', disease, statusColor, _lighten(statusColor, 0.85)),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          flex: 1,
          child: _buildDiagnosisCard('Severity', severity, sevColor, _lighten(sevColor, 0.85)),
        ),
      ],
    );
  }

  static pw.Widget _buildDiagnosisCard(String label, String value, PdfColor accent, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: accent, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              label.toUpperCase(),
              style: _ts(fontSize: 7, color: PdfColors.white, bold: true),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _sanitize(value),
            style: _ts(fontSize: 11, color: _textDark, bold: true),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ─── Confidence Meter ──────────────────────────────────────────────────
  static pw.Widget _buildConfidenceMeter(double confidence) {
    final barColor = confidence >= 80 ? _green700 : confidence >= 60 ? _amber700 : _red700;
    final fraction = (confidence / 100).clamp(0.0, 1.0);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _grey300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Confidence Score',
                style: _ts(fontSize: 10, color: _textDark, bold: true),
              ),
              pw.Text(
                '${confidence.toStringAsFixed(1)}%',
                style: _ts(fontSize: 14, color: barColor, bold: true),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Stack(
            children: [
              pw.Container(
                height: 8,
                decoration: pw.BoxDecoration(
                  color: _grey300,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.Container(
                width: 300 * fraction,
                height: 8,
                decoration: pw.BoxDecoration(
                  color: barColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Bullet List ───────────────────────────────────────────────────────
  static pw.Widget _buildBulletList(List<String> items, PdfColor bg, PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _lighten(accent, 0.6), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items.take(8).map((item) { // Limit to 8 items per section
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 5),
                  width: 4,
                  height: 4,
                  decoration: pw.BoxDecoration(
                    color: accent,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    _sanitize(item),
                    style: _ts(fontSize: 9, color: _textDark, height: 1.3),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Numbered List ─────────────────────────────────────────────────────
  static pw.Widget _buildNumberedList(List<String> steps, PdfColor bg, PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _lighten(accent, 0.6), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: steps.asMap().entries.map((e) {
          final idx = e.key;
          final step = _sanitize(e.value);
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 18,
                  height: 18,
                  decoration: pw.BoxDecoration(
                    color: accent,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '${idx + 1}',
                      style: _ts(fontSize: 8, color: PdfColors.white, bold: true),
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    step,
                    style: _ts(fontSize: 9, color: _textDark, height: 1.3),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Additional Info ───────────────────────────────────────────────────
  static pw.Widget _buildAdditionalInfo(String info) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _purple100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _purpleBdr, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(
              color: _purple400,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                'i',
                style: _ts(fontSize: 10, color: PdfColors.white, bold: true),
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              _sanitize(info),
              style: _ts(fontSize: 9, color: _textDark, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Disclaimer ────────────────────────────────────────────────────────
  static pw.Widget _buildDisclaimer() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _amber100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _amberAcc, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(
              color: _amber700,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                '!',
                style: _ts(fontSize: 10, color: PdfColors.white, bold: true),
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Consultation Recommended',
                  style: _ts(fontSize: 10, color: _amber700, bold: true),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Please consult with certified agricultural experts before taking action.',
                  style: _ts(fontSize: 8, color: const PdfColor(0.4, 0.3, 0.2), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  /// Sanitize text to remove problematic characters
  static String _sanitize(String text) {
    if (text.isEmpty) return text;

    // Replace common problematic characters
    return text
        .replaceAll('🌿', '')
        .replaceAll('═', '-')
        .replaceAll('🪴', '')
        .replaceAll('🏥', '')
        .replaceAll('✅', '✓')
        .replaceAll('💡', '')
        .replaceAll('⚙', '')
        .replaceAll('•', '-')
        .replaceAll('·', '-')
        .replaceAll('●', '-')
        .replaceAll('○', '-')
        .replaceAll('◆', '-')
        .replaceAll('◇', '-')
        .replaceAll('■', '-')
        .replaceAll('□', '-')
        .replaceAll('►', '>')
        .replaceAll('◄', '<')
        .replaceAll('▲', '^')
        .replaceAll('▼', 'v')
        .trim();
  }

  static PdfColor _lighten(PdfColor c, double amount) => PdfColor(
    c.red + (1.0 - c.red) * amount,
    c.green + (1.0 - c.green) * amount,
    c.blue + (1.0 - c.blue) * amount,
  );

  static PdfColor _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return const PdfColor(0.8, 0.2, 0.2);
      case 'high': case 'severe': return _red700;
      case 'medium': case 'moderate': return _amber700;
      case 'low': case 'mild': return const PdfColor(0.9, 0.7, 0.1);
      default: return _grey600;
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

  static List<String> _parseList(dynamic data) {
    if (data is List) return data.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    if (data is String) return data.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return [];
  }

  static Future<File> _savePdf(pw.Document pdf) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/AgriGuard_Report_$timestamp.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}