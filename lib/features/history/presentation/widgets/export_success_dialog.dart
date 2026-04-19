import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import '../../../../../core/widgets/app_themes.dart';

class ExportSuccessDialog extends StatefulWidget {
  final File file;
  final String fileType;
  final int scanCount;

  const ExportSuccessDialog({
    super.key,
    required this.file,
    required this.fileType,
    required this.scanCount,
  });

  @override
  State<ExportSuccessDialog> createState() => _ExportSuccessDialogState();
}

class _ExportSuccessDialogState extends State<ExportSuccessDialog> {
  bool _isSharing = false;

  Future<void> _shareFile() async {
    setState(() => _isSharing = true);
    HapticFeedback.mediumImpact();
    try {
      await Share.shareXFiles(
        [XFile(widget.file.path)],
        subject: 'AgriGuard Scan History',
        text: 'Here is my complete scan history from AgriGuard',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    final fileName = p.basename(widget.file.path);
    final displayFileName = fileName.length > 28 ? '...${fileName.substring(fileName.length - 25)}' : fileName;
    final fileSize = _formatFileSize(widget.file.lengthSync());

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 14),
              Text('Export Complete', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 4),
              Text('Your file has been generated', style: TextStyle(fontSize: 13, color: captionColor)),
              const SizedBox(height: 16),

              // File info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.insert_drive_file_rounded, 'File Name', displayFileName, AppColors.info, isDark),
                    const SizedBox(height: 10),
                    _infoRow(Icons.storage_rounded, 'File Size', fileSize, AppColors.secondary, isDark),
                    const SizedBox(height: 10),
                    _infoRow(Icons.analytics_rounded, 'Total Scans', '${widget.scanCount} scans', AppColors.warning, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Share button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _shareFile,
                  icon: _isSharing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.share_rounded, size: 18),
                  label: Text(_isSharing ? 'Sharing...' : 'Share File', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Close button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    side: BorderSide(color: border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkCaption : AppColors.lightCaption, fontWeight: FontWeight.w600)),
              Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
