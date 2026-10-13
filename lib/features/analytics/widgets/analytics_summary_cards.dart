import 'package:flutter/material.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';

class AnalyticsSummaryCards extends StatelessWidget {
  final int total;
  final double healthyPct;
  final int diseasedThisMonth;
  final Color card;
  final Color border;
  final Color text;
  final Color caption;
  final TranslationService t;

  const AnalyticsSummaryCards({
    super.key,
    required this.total,
    required this.healthyPct,
    required this.diseasedThisMonth,
    required this.card,
    required this.border,
    required this.text,
    required this.caption,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _CardData(
        label: t.get('total_scans'),
        value: '$total',
        icon: Icons.document_scanner_rounded,
        color: AppColors.primary,
        bgColor: AppColors.primary.withValues(alpha: 0.10),
      ),
      _CardData(
        label: t.get('healthy_pct'),
        value: '${healthyPct.toStringAsFixed(0)}%',
        icon: Icons.eco_rounded,
        color: AppColors.success,
        bgColor: AppColors.success.withValues(alpha: 0.10),
      ),
      _CardData(
        label: t.get('diseased_this_month'),
        value: '$diseasedThisMonth',
        icon: Icons.bug_report_rounded,
        color: AppColors.warning,
        bgColor: AppColors.warning.withValues(alpha: 0.10),
      ),
    ];

    return Row(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsetsDirectional.only(end: i < items.length - 1 ? 10 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: item.color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: caption,
                    height: 1.3,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _CardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
