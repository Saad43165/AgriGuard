import 'dart:io';

import 'package:agriguard_fyp/features/home/screens/PdfDialogs/SuccessPdfDialog/pdf_action_button.dart';
import 'package:agriguard_fyp/features/home/screens/PdfDialogs/SuccessPdfDialog/pdf_info_chip.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../SavePdfDialog/save_options_dialog.dart';
import '../services/pdf_dialog_helper.dart';

class PdfSuccessDialog extends StatelessWidget {
  final File pdfFile;

  const PdfSuccessDialog({super.key, required this.pdfFile});

  @override
  Widget build(BuildContext context) {
    final sizeKB = (pdfFile.lengthSync() / 1024).toStringAsFixed(1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTime = DateFormat('HH:mm').format(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success indicator
            _buildSuccessHeader(isDark),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info chips row
                  Row(
                    children: [
                      PdfInfoChip(
                        icon: Icons.insert_drive_file_rounded,
                        label: 'Size',
                        value: '$sizeKB KB',
                        color: const Color(0xFF6366F1),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      PdfInfoChip(
                        icon: Icons.picture_as_pdf_rounded,
                        label: 'Format',
                        value: 'PDF',
                        color: const Color(0xFFEF4444),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      PdfInfoChip(
                        icon: Icons.access_time_rounded,
                        label: 'Created',
                        value: currentTime,
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: PdfActionButton(
                          icon: Icons.ios_share_rounded,
                          label: 'Share',
                          isPrimary: false,
                          onPressed: () => _handleShare(context),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PdfActionButton(
                          icon: Icons.download_rounded,
                          label: 'Save',
                          isPrimary: true,
                          onPressed: () => _handleSave(context),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Close button
                  _buildCloseButton(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF059669),
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'PDF Generated Successfully',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Close',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    Navigator.pop(context);
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: 'AgriGuard Plant Health Report',
      );
    } catch (e) {
      if (context.mounted) {
        PdfDialogHelper.showSnackBar(
          context,
          'Failed to share: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => SaveOptionsDialog(
        currentFileName: pdfFile.path.split('/').last,
      ),
    );

    if (result == null || !context.mounted) return;

    final fileName = result['fileName'] as String;
    final location = result['location'] as String;

    await PdfDialogHelper.saveToLocation(
      context: context,
      pdfFile: pdfFile,
      fileName: fileName,
      location: location,
    );
  }
}