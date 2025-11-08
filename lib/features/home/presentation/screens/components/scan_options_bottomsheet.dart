// lib/features/scan_history/presentation/components/scan_options_bottomsheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../services/pdf_generator_service.dart';

class ScanOptionsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> scan;
  final VoidCallback onDelete;
  final VoidCallback? onShare;

  const ScanOptionsBottomSheet({
    super.key,
    required this.scan,
    required this.onDelete,
    this.onShare,
  });

  @override
  State<ScanOptionsBottomSheet> createState() => _ScanOptionsBottomSheetState();
}

class _ScanOptionsBottomSheetState extends State<ScanOptionsBottomSheet> {
  bool _isGeneratingPdf = false;

  @override
  void dispose() {
    super.dispose();
  }

  // FIXED: DO NOT DELETE IMAGE FILE
  // Only delete Firestore document
  // Image will be cleaned by OS when cache is full
  Future<void> _generateAndShowPdf(BuildContext context) async {
    if (_isGeneratingPdf) return;

    setState(() => _isGeneratingPdf = true);

    // Close bottom sheet
    if (Navigator.canPop(context)) Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) {
      setState(() => _isGeneratingPdf = false);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
    );

    try {
      final pdfFile = await PdfShareService.generateScanPdf(widget.scan)
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await _showPdfSuccessDialog(context, pdfFile);
    } on TimeoutException {
      _handleError(context, 'PDF generation timed out. Please try again.');
    } catch (e, s) {
      debugPrint('PDF Error: $e\n$s');
      _handleError(context, 'Failed to generate PDF: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _handleError(BuildContext context, String message) {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _showPdfSuccessDialog(BuildContext context, File pdfFile) async {
    final sizeKB = (await pdfFile.length() / 1024).toStringAsFixed(1);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 12),
            const Text('PDF Generated!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your scan report is ready.'),
            const SizedBox(height: 16),
            _infoRow(context, 'Size', '$sizeKB KB'),
            _infoRow(context, 'Location', 'Temporary'),
            _infoRow(context, 'Format', 'PDF'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _savePdfToDownloads(context, pdfFile);
            },
            icon: const Icon(Icons.save_alt, size: 18),
            label: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _savePdfToDownloads(BuildContext context, File pdfFile) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const _LoadingDialog());

      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception('Storage not available');

      final downloadDir = Directory('${dir.path}/Download');
      if (!await downloadDir.exists()) await downloadDir.create(recursive: true);

      final fileName = 'AgriGuard_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedFile = await pdfFile.copy('${downloadDir.path}/$fileName');

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Saved to Downloads: ${savedFile.path.split('/').last}')),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red[700]),
        );
      }
    }
  }

  Future<void> _copyResultsToClipboard(BuildContext context) async {
    final diagnosis = widget.scan['diagnosis']?.toString() ?? 'Unknown';
    final confidence = double.tryParse(widget.scan['confidence']?.toString() ?? '0') ?? 0.0;
    final date = _formatDate(widget.scan['timestamp']);

    final text = '''
AGRI GUARD SCAN RESULT

Diagnosis: $diagnosis
Confidence: ${confidence.toStringAsFixed(1)}%
Date: $date

RECOMMENDATIONS:
${_getRecommendations(diagnosis, confidence)}

Generated by AgriGuard
'''.trim();

    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Copied to clipboard!'),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getRecommendations(String diagnosis, double confidence) {
    final recs = <String>[];
    if (confidence < 60) {
      recs.addAll(['• Rescan with better lighting', '• Ensure leaf is in focus']);
    }
    if (diagnosis.toLowerCase().contains('healthy')) {
      recs.addAll(['• Continue regular care', '• Monitor weekly']);
    } else {
      recs.addAll(['• Isolate affected plant', '• Consult local expert']);
    }
    return recs.join('\n');
  }

  String _formatDate(dynamic timestamp) {
    try {
      DateTime? dt;
      if (timestamp is int) dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      else if (timestamp is String) dt = DateTime.tryParse(timestamp);
      else if (timestamp is DateTime) dt = timestamp;
      return dt != null ? '${dt.day}/${dt.month}/${dt.year}' : 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text('Scan Options', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _optionTile(
                    context,
                    icon: Icons.picture_as_pdf_rounded,
                    color: Colors.blue[600]!,
                    title: 'Generate PDF Report',
                    subtitle: 'Download detailed analysis',
                    onTap: _isGeneratingPdf ? null : () => _generateAndShowPdf(context),
                    trailing: _isGeneratingPdf
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : null,
                  ),
                  _optionTile(
                    context,
                    icon: Icons.content_copy_rounded,
                    color: Colors.green[600]!,
                    title: 'Copy Results',
                    subtitle: 'Share as text',
                    onTap: () {
                      Navigator.pop(context);
                      _copyResultsToClipboard(context);
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _optionTile(
                    context,
                    icon: Icons.delete_outline_rounded,
                    color: Colors.red[600]!,
                    title: 'Delete Scan',
                    subtitle: 'Remove from history',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDelete(); // ONLY DELETE FIRESTORE DOC
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required String subtitle,
        required VoidCallback? onTap,
        Widget? trailing,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Loading Dialog
class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          const Text('Please wait...', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}
