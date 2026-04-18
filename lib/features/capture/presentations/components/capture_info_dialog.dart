import 'package:flutter/material.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/widgets/app_themes.dart';

class CaptureInfoDialog extends StatelessWidget {
  const CaptureInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final translation = TranslationService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          translation.get('info_title'),
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoStep(context, Icons.analytics_rounded, translation.get('info_step1'), translation.get('info_step1_desc'), AppColors.info, isDark),
                  const SizedBox(height: 12),
                  _buildInfoStep(context, Icons.camera_alt_rounded, translation.get('info_step2'), translation.get('info_step2_desc'), AppColors.primary, isDark),
                  const SizedBox(height: 12),
                  _buildInfoStep(context, Icons.task_alt_rounded, translation.get('info_step3'), translation.get('info_step3_desc'), AppColors.warning, isDark),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning, size: 16),
                            const SizedBox(width: 6),
                            Text(translation.get('info_tips'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.warning)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTip(translation.get('info_tip1'), captionColor),
                        _buildTip(translation.get('info_tip2'), captionColor),
                        _buildTip(translation.get('info_tip3'), captionColor),
                        _buildTip(translation.get('info_tip4'), captionColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(translation.get('got_it'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoStep(BuildContext context, IconData icon, String title, String description, Color color, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)),
              const SizedBox(height: 2),
              Text(description, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkCaption : AppColors.lightCaption, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, height: 1.3)),
    );
  }
}
