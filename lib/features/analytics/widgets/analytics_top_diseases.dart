import 'package:flutter/material.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import 'analytics_card_shell.dart';

class AnalyticsTopDiseases extends StatelessWidget {
  final Map<String, int> diseases;
  final Color card;
  final Color border;
  final Color text;
  final Color caption;
  final TranslationService t;

  const AnalyticsTopDiseases({
    super.key,
    required this.diseases,
    required this.card,
    required this.border,
    required this.text,
    required this.caption,
    required this.t,
  });

  static const _colors = [
    AppColors.error,
    AppColors.warning,
    AppColors.info,
    AppColors.secondary,
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    if (diseases.isEmpty) return const SizedBox.shrink();
    final maxVal = diseases.values.reduce((a, b) => a > b ? a : b);

    return AnalyticsCardShell(
      card: card,
      border: border,
      icon: Icons.bug_report_rounded,
      title: t.get('top_diseases'),
      textColor: text,
      child: Column(
        children: diseases.entries.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = maxVal == 0 ? 0.0 : e.value / maxVal;
          final color = _colors[i % _colors.length];
          final rank = i + 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rank badge
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${e.value} case${e.value != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LayoutBuilder(
                        builder: (ctx, constraints) => Stack(
                          children: [
                            Container(
                              height: 6,
                              width: constraints.maxWidth,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              height: 6,
                              width: constraints.maxWidth * pct,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
