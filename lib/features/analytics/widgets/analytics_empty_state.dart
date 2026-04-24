import 'package:flutter/material.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';

class AnalyticsEmptyState extends StatelessWidget {
  final Color textColor;
  final Color captionColor;
  final Color card;
  final Color border;
  final TranslationService t;

  const AnalyticsEmptyState({
    super.key,
    required this.textColor,
    required this.captionColor,
    required this.card,
    required this.border,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.20),
                ),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              t.get('no_data_yet'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t.get('scan_plants_to_see'),
              style: TextStyle(fontSize: 14, color: captionColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Text(
                t.get('analytics_guidance'),
                style: TextStyle(
                  fontSize: 13,
                  color: captionColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
