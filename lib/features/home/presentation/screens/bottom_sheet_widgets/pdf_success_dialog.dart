// lib/features/scan_history/presentation/components/scan_options_bottomsheet/widgets/pdf_success_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'loading_dialog.dart';

class PdfSuccessDialog extends StatelessWidget {
  final File pdfFile;

  const PdfSuccessDialog({super.key, required this.pdfFile});

  Future<void> _saveToDownloads(BuildContext context) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const LoadingDialog());

      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception('Storage not available');

      final downloadDir = Directory('${dir.path}/Download');
      if (!await downloadDir.exists()) await downloadDir.create(recursive: true);

      final fileName = 'AgriGuard_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedFile = await pdfFile.copy('${downloadDir.path}/$fileName');

      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Saved: ${savedFile.path.split('/').last}')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizeKB = (pdfFile.lengthSync() / 1024).toStringAsFixed(1);
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF1A1A2E) : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 12),
          const Text('PDF Ready!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your scan report has been generated successfully.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 20),
          _infoRow(context, Icons.insert_drive_file_rounded, 'Size', '$sizeKB KB'),
          const SizedBox(height: 8),
          _infoRow(context, Icons.access_time_rounded, 'Created', 'Just now'),
          const SizedBox(height: 8),
          _infoRow(context, Icons.picture_as_pdf_rounded, 'Format', 'PDF Document'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)))),
        FilledButton.icon(
          onPressed: () => _saveToDownloads(context),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Save to Downloads'),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.7))),
        Expanded(child: Text(value, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.9)))),
      ],
    );
  }
}