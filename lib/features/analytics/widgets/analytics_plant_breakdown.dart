import 'package:flutter/material.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import 'analytics_card_shell.dart';

class AnalyticsPlantBreakdown extends StatelessWidget {
  final Map<String, int> plants;
  final Color card;
  final Color border;
  final Color text;
  final Color caption;
  final TranslationService t;

  const AnalyticsPlantBreakdown({
    super.key,
    required this.plants,
    required this.card,
    required this.border,
    required this.text,
    required this.caption,
    required this.t,
  });

  // A palette of complementary botanical colors
  static const _dotColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.info,
    Color(0xFF52B788),
    Color(0xFF74C69D),
    Color(0xFF95D5B2),
  ];

  @override
  Widget build(BuildContext context) {
    if (plants.isEmpty) return const SizedBox.shrink();

    final total = plants.values.fold(0, (a, b) => a + b);
    final sorted = plants.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AnalyticsCardShell(
      card: card,
      border: border,
      icon: Icons.local_florist_rounded,
      title: t.get('plant_health_breakdown'),
      textColor: text,
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = total == 0 ? 0.0 : e.value / total;
          final dotColor = _dotColors[i % _dotColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: text,
                        ),
                      ),
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dotColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${e.value})',
                      style: TextStyle(fontSize: 11, color: caption),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (ctx, constraints) => Stack(
                    children: [
                      Container(
                        height: 5,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: dotColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        height: 5,
                        width: constraints.maxWidth * pct,
                        decoration: BoxDecoration(
                          color: dotColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3),
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
