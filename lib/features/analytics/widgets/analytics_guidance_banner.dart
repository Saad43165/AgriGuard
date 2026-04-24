import 'package:flutter/material.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';

class AnalyticsGuidanceBanner extends StatelessWidget {
  final Color text;
  final TranslationService t;

  const AnalyticsGuidanceBanner({
    super.key,
    required this.text,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.get('analytics_guidance'),
              style: TextStyle(fontSize: 13, color: text, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
