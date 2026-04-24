import 'package:flutter/material.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import 'analytics_card_shell.dart';

class AnalyticsMonthlyActivity extends StatelessWidget {
  final Map<String, int> monthly;
  final Color card;
  final Color border;
  final Color text;
  final Color caption;
  final TranslationService t;

  const AnalyticsMonthlyActivity({
    super.key,
    required this.monthly,
    required this.card,
    required this.border,
    required this.text,
    required this.caption,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    if (monthly.isEmpty) return const SizedBox.shrink();

    final entries = monthly.entries.toList();
    final maxVal = entries.fold<int>(0, (m, e) => e.value > m ? e.value : m);

    // ---- Fixed layout metrics to prevent overflow ----
    const double valuesRowH = 20;   // top numbers row
    const double barsRowH = 96;     // bars drawing row
    const double labelsRowH = 18;   // month labels row
    const double gap1 = 6;
    const double gap2 = 8;
    const double minBarHeight = 3;
    const double barRadius = 6;

    final totalHeight = valuesRowH + gap1 + barsRowH + gap2 + labelsRowH;

    return AnalyticsCardShell(
      card: card,
      border: border,
      icon: Icons.calendar_month_rounded,
      title: t.get('monthly_activity_6'),
      textColor: text,
      child: SizedBox(
        height: totalHeight,
        child: Column(
          children: [
            // ---------------- Values row ----------------
            SizedBox(
              height: valuesRowH,
              child: Row(
                children: entries.map((e) {
                  final isCurrentMonth = e.key == entries.last.key;
                  return Expanded(
                    child: Center(
                      child: Text(
                        '${e.value}',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isCurrentMonth ? AppColors.primary : caption,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: gap1),

            // ---------------- Bars row ----------------
            SizedBox(
              height: barsRowH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: entries.map((e) {
                  final isCurrentMonth = e.key == entries.last.key;
                  final pct = maxVal == 0 ? 0.0 : (e.value / maxVal).clamp(0.0, 1.0);
                  final h = (barsRowH * pct).clamp(minBarHeight, barsRowH);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.easeOutCubic,
                          height: h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isCurrentMonth
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.28),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(barRadius),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: gap2),

            // ---------------- Month labels row ----------------
            SizedBox(
              height: labelsRowH,
              child: Row(
                children: entries.map((e) {
                  final isCurrentMonth = e.key == entries.last.key;
                  return Expanded(
                    child: Center(
                      child: Text(
                        e.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrentMonth ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrentMonth ? AppColors.primary : caption,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}