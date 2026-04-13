import 'package:flutter/material.dart';
import '../../../../core/services/translation_service.dart';

class FeatureHighlights extends StatelessWidget {
  const FeatureHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final translation = TranslationService();

    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  translation.get('features_title'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildFeatureRow(
              context,
              translation,
              icon: Icons.search_rounded,
              titleKey: 'feature_identify',
              descKey: 'feature_identify_desc',
              color: Colors.green.shade600,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildFeatureRow(
              context,
              translation,
              icon: Icons.health_and_safety_rounded,
              titleKey: 'feature_disease',
              descKey: 'feature_disease_desc',
              color: Colors.orange.shade600,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildFeatureRow(
              context,
              translation,
              icon: Icons.medication_rounded,
              titleKey: 'feature_treatment',
              descKey: 'feature_treatment_desc',
              color: Colors.blue.shade600,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildFeatureRow(
              context,
              translation,
              icon: Icons.offline_bolt_rounded,
              titleKey: 'feature_offline',
              descKey: 'feature_offline_desc',
              color: Colors.purple.shade600,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureRow(
      BuildContext context,
      TranslationService translation, {
        required IconData icon,
        required String titleKey,
        required String descKey,
        required Color color,
        required bool isDark,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E).withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.5,
        ),

      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translation.get(titleKey),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  translation.get(descKey),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}