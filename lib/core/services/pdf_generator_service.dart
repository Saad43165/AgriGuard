import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class PdfShareService {
  static Future<File> generateScanPdf(Map<String, dynamic> scan) async {
    final pdf = pw.Document();

    // Load image
    Uint8List? imageBytes;
    try {
      imageBytes = await _loadScanImage(scan);
    } catch (e) {
      print('Could not load image: $e');
    }

    // Extract scan data
    final plantName = scan['plantName']?.toString() ?? scan['cropType']?.toString() ?? 'Unknown Plant';
    final diagnosis = scan['diagnosis']?.toString() ?? scan['diseaseName']?.toString() ?? 'Unknown';
    final confidence = _parseConfidence(scan['confidence']);
    final severity = scan['severity']?.toString() ?? 'Unknown';
    final treatment = scan['treatment']?.toString() ?? scan['remediation']?.toString() ?? 'No treatment information available';
    final symptoms = _parseList(scan['symptoms']);
    final precautions = _parseList(scan['precautions']);
    final scanDate = _parseDate(scan['timestamp'] ?? scan['scanDate'] ?? scan['createdAt']);
    final isHealthy = scan['isHealthy'] == true || diagnosis.toLowerCase().contains('healthy');

    // Determine severity color
    final severityColor = _getSeverityColor(severity);
    final statusColor = isHealthy ? const PdfColor(0.133, 0.545, 0.133) : const PdfColor(1.0, 0.549, 0.0);

    // Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(
          top: 60,      // Increased top margin for all pages
          bottom: 40,
          left: 0,
          right: 0,
        ),
        build: (context) => [
          // HEADER
          _buildProfessionalHeader(scanDate),

          pw.SizedBox(height: 35),

          // MAIN CONTENT
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 45),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // TITLE BANNER
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(24),
                  decoration: pw.BoxDecoration(
                    gradient: const pw.LinearGradient(
                      colors: [
                        PdfColor.fromInt(0xFFE8F5E9),
                        PdfColor.fromInt(0xFFF1F8E9),
                      ],
                    ),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                    border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFA5D6A7),
                      width: 1.5,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PLANT HEALTH ANALYSIS REPORT',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF2E7D32),
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        height: 1,
                        color: const PdfColor.fromInt(0xFFA5D6A7),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Report ID: AGR${DateTime.now().millisecondsSinceEpoch}',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColor.fromInt(0xFF616161),
                            ),
                          ),
                          pw.Text(
                            'Date: $scanDate',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColor.fromInt(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // IMAGE SECTION (CENTERED)
                if (imageBytes != null) ...[
                  pw.Center(
                    child: pw.Container(
                      width: 400,
                      height: 280,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        border: pw.Border.all(
                          color: const PdfColor.fromInt(0xFFE0E0E0),
                          width: 2,
                        ),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 10,
                        verticalRadius: 10,
                        child: pw.Image(
                          pw.MemoryImage(imageBytes),
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 35),
                ],

                // DIAGNOSIS HEADER
                _buildSectionHeader('Diagnosis', const PdfColor.fromInt(0xFF1976D2)),
                pw.SizedBox(height: 20),

                // DIAGNOSIS CARDS (3 cards in a row)
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildDiagnosisCard(
                        'Plant Species',
                        plantName,
                        const PdfColor.fromInt(0xFF1976D2),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: _buildDiagnosisCard(
                        'Disease Name',
                        diagnosis,
                        statusColor,
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: _buildDiagnosisCard(
                        'Severity Level',
                        severity,
                        severityColor,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 35),

                // SYMPTOMS SECTION (kept together)
                if (symptoms.isNotEmpty)
                  pw.Wrap(
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Observed Symptoms', const PdfColor.fromInt(0xFFD32F2F)),
                          pw.SizedBox(height: 14),
                          _buildBulletList(
                            symptoms,
                            const PdfColor.fromInt(0xFFFFEBEE),
                            const PdfColor.fromInt(0xFFD32F2F),
                          ),
                          pw.SizedBox(height: 28),
                        ],
                      ),
                    ],
                  ),

                // TREATMENT SECTION (kept together)
                pw.Wrap(
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Treatment Recommendations', const PdfColor.fromInt(0xFF388E3C)),
                        pw.SizedBox(height: 14),
                        _buildTreatmentSection(
                          treatment,
                          const PdfColor.fromInt(0xFFE8F5E9),
                          const PdfColor.fromInt(0xFF388E3C),
                        ),
                        pw.SizedBox(height: 28),
                      ],
                    ),
                  ],
                ),

                // PRECAUTIONS SECTION (kept together)
                if (precautions.isNotEmpty)
                  pw.Wrap(
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Precautions & Prevention', const PdfColor.fromInt(0xFFF57C00)),
                          pw.SizedBox(height: 14),
                          _buildBulletList(
                            precautions,
                            const PdfColor.fromInt(0xFFFFF3E0),
                            const PdfColor.fromInt(0xFFF57C00),
                          ),
                          pw.SizedBox(height: 28),
                        ],
                      ),
                    ],
                  ),

                // IMPORTANT NOTE
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(18),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFFFF8E1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                    border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFFFD54F),
                      width: 1.5,
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFFFB300),
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Container(
                          width: 14,
                          height: 14,
                          child: pw.Center(
                            child: pw.Text(
                              'i',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 14),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Professional Consultation Recommended',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0xFFE65100),
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'This AI-generated analysis serves as a preliminary guide. For critical plant health issues, persistent problems, or before applying any treatments, please consult with a certified agricultural expert or plant pathologist for professional diagnosis.',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColor.fromInt(0xFF5D4037),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 45),

          // FOOTER
          _buildFooter(),
        ],
      ),
    );

    return await _savePdf(pdf);
  }

  static pw.Widget _buildProfessionalHeader(String date) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 45, vertical: 24),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFAFAFA),
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromInt(0xFF66BB6A),
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
                  color: const PdfColor.fromInt(0xFF2E7D32),
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Plant Health Analysis System',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColor.fromInt(0xFF757575),
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF66BB6A),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(25)),
            ),
            child: pw.Text(
              'REPORT',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 14, bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: color, width: 4),
          bottom: pw.BorderSide(
            color: const PdfColor.fromInt(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  static pw.Widget _buildDiagnosisCard(String label, String value, PdfColor color) {
    // Create lighter versions of the color manually
    final lightBg = _getLightColor(color, 0.1);
    final lightBorder = _getLightColor(color, 0.3);

    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(
          color: lightBorder,
          width: 2,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: color, width: 3),
              ),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10),
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF212121),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Helper method to create lighter colors
  static PdfColor _getLightColor(PdfColor color, double opacity) {
    // Mix the color with white based on opacity
    final white = 1.0;
    final factor = 1.0 - opacity;

    return PdfColor(
      color.red + (white - color.red) * factor,
      color.green + (white - color.green) * factor,
      color.blue + (white - color.blue) * factor,
    );
  }
  static pw.Widget _buildBulletList(List<String> items, PdfColor bgColor, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items.map((item) {
          final cleanItem = _cleanText(item);
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 5),
                  width: 5,
                  height: 5,
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Text(
                    cleanItem,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFF424242),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildTreatmentSection(String treatment, PdfColor bgColor, PdfColor accentColor) {
    final steps = _parseTreatmentLines(treatment);
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = _cleanText(entry.value);
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 22,
                  height: 22,
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '${index + 1}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Text(
                    step.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim(),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFF424242),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 45),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFAFAFA),
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColor.fromInt(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'AgriGuard Plant Health Analysis',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF616161),
                ),
              ),
              pw.Text(
                'support@agriguard.com',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFF757575),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Copyright ${DateTime.now().year} AgriGuard. All rights reserved. This report is confidential and intended solely for agricultural consultation purposes.',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF9E9E9E),
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _cleanText(String text) {
    return text.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim();
  }

  static PdfColor _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return const PdfColor.fromInt(0xFFD32F2F);
      case 'medium':
      case 'moderate':
        return const PdfColor.fromInt(0xFFF57C00);
      case 'low':
      case 'mild':
        return const PdfColor.fromInt(0xFFFBC02D);
      default:
        return const PdfColor.fromInt(0xFF757575);
    }
  }

  static String _getConfidenceLabel(double confidence) {
    if (confidence >= 90) return 'Excellent';
    if (confidence >= 75) return 'Very Good';
    if (confidence >= 60) return 'Good';
    if (confidence >= 40) return 'Fair';
    return 'Low';
  }

  static Future<Uint8List?> _loadScanImage(Map<String, dynamic> scan) async {
    if (scan['imageBase64'] != null && scan['imageBase64'].toString().isNotEmpty) {
      try {
        return base64Decode(scan['imageBase64']);
      } catch (e) {
        print('Base64 decode error: $e');
      }
    }

    if (scan['imagePath'] != null && scan['imagePath'].toString().isNotEmpty) {
      try {
        final file = File(scan['imagePath']);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      } catch (e) {
        print('File read error: $e');
      }
    }

    return null;
  }

  static double _parseConfidence(dynamic confidence) {
    if (confidence == null) return 0.0;
    if (confidence is double) return confidence;
    if (confidence is int) return confidence.toDouble();
    if (confidence is String) {
      return double.tryParse(confidence) ?? 0.0;
    }
    return 0.0;
  }

  static List<String> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
    if (data is String && data.isNotEmpty) {
      return data.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }
    return [];
  }

  static List<String> _parseTreatmentLines(String treatment) {
    return treatment
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList();
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
        return DateFormat('MMMM dd, yyyy').format(dt);
      }
    } catch (e) {
      print('Date parse error: $e');
    }
    return 'Unknown date';
  }

  static Future<File> _savePdf(pw.Document pdf) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'AgriGuard_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    print('PDF saved: ${file.path}');
    return file;
  }
}