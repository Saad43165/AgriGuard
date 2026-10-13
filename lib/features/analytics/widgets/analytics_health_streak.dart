import 'package:flutter/material.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';

class AnalyticsHealthStreak extends StatelessWidget {
  final double healthyPct;
  final int thisMonthDiseased;
  final int lastMonthDiseased;
  final int scanStreak;
  final Color card;
  final Color border;
  final Color text;
  final Color caption;
  final TranslationService t;

  const AnalyticsHealthStreak({
    super.key,
    required this.healthyPct,
    required this.thisMonthDiseased,
    required this.lastMonthDiseased,
    required this.scanStreak,
    required this.card,
    required this.border,
    required this.text,
    required this.caption,
    required this.t,
  });

  Color get _trendColor {
    if (thisMonthDiseased > lastMonthDiseased) return AppColors.error;
    if (thisMonthDiseased < lastMonthDiseased) return AppColors.success;
    return AppColors.warning;
  }

  String _trendText() {
    if (lastMonthDiseased == 0 && thisMonthDiseased == 0) return t.get('trend_same');
    if (thisMonthDiseased > lastMonthDiseased) return t.get('trend_up');
    if (thisMonthDiseased < lastMonthDiseased) return t.get('trend_down');
    return t.get('trend_same');
  }

  Color get _ringColor {
    if (healthyPct >= 70) return AppColors.success;
    if (healthyPct >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final trendColor = _trendColor;

    return Row(
      children: [
        // ── Health Ring ──────────────────────────────
        Expanded(
          child: _StatCard(
            card: card,
            border: border,
            child: Column(
              children: [
                Text(
                  t.get('health_score'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: caption,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 68,
                  height: 68,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: healthyPct / 100,
                        strokeWidth: 7,
                        backgroundColor: AppColors.error.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(_ringColor),
                        strokeCap: StrokeCap.round,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${healthyPct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: text,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ── Disease Trend ────────────────────────────
        Expanded(
          child: _StatCard(
            card: card,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.get('disease_rate'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: caption,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$thisMonthDiseased',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: trendColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _trendText(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: trendColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ── Scan Streak ──────────────────────────────
        Expanded(
          child: _StatCard(
            card: card,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.get('scan_streak'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: caption,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$scanStreak',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                        height: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsetsDirectional.only(bottom: 2, start: 4),
                      child: Text('🔥', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  t.get('days_scanning'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: caption,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Color card;
  final Color border;
  final Widget child;

  const _StatCard({
    required this.card,
    required this.border,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}
