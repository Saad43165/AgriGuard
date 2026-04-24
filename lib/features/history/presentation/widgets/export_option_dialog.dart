import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/widgets/app_themes.dart';

class ExportOptionsDialog extends StatelessWidget {
  final VoidCallback onPdfExport;
  final VoidCallback onCsvExport;

  const ExportOptionsDialog({
    super.key,
    required this.onPdfExport,
    required this.onCsvExport,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
    isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor =
    isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.file_download_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Export History',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textColor)),
                      Text('Choose your format',
                          style: TextStyle(
                              fontSize: 12, color: captionColor)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: border),
              const SizedBox(height: 16),
              _buildOption(
                context,
                icon: Icons.picture_as_pdf_rounded,
                title: 'PDF Report',
                subtitle: 'Professional formatted document',
                badge: 'Recommended',
                iconColor: AppColors.error,
                isDark: isDark,
                border: border,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  onPdfExport();
                },
              ),
              const SizedBox(height: 10),
              _buildOption(
                context,
                icon: Icons.table_chart_rounded,
                title: 'CSV Spreadsheet',
                subtitle: 'Data table for analysis',
                badge: 'Excel Ready',
                iconColor: AppColors.primary,
                isDark: isDark,
                border: border,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  onCsvExport();
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                    side: BorderSide(color: border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required String badge,
        required Color iconColor,
        required bool isDark,
        required Color border,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : AppColors.lightBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkOnSurface
                                : AppColors.lightOnSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badge,
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkCaption
                                : AppColors.lightCaption)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkCaption
                      : AppColors.lightCaption),
            ],
          ),
        ),
      ),
    );
  }
}