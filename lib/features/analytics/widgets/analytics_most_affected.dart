import 'package:flutter/material.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import 'analytics_card_shell.dart';

class AnalyticsMostAffected extends StatelessWidget {
  final String mostAffectedPlant;
  final Color card;
  final Color border;
  final Color text;
  final Color caption;
  final TranslationService t;

  const AnalyticsMostAffected({
    super.key,
    required this.mostAffectedPlant,
    required this.card,
    required this.border,
    required this.text,
    required this.caption,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return AnalyticsCardShell(
      card: card,
      border: border,
      icon: Icons.warning_amber_rounded,
      title: t.get('most_affected_plant'),
      textColor: text,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.error, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mostAffectedPlant,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  t.get('most_disease_detections'),
                  style: TextStyle(fontSize: 13, color: caption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}