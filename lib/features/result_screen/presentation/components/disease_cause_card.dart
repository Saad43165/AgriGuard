import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/widgets/app_themes.dart';

class DiseaseCausesCard extends StatelessWidget {
  final List<dynamic> causes;
  const DiseaseCausesCard({super.key, required this.causes});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (causes.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: List.generate(causes.length, (i) {
          final causeData = causes[i];
          String text;
          if (causeData is Map) {
            text = t.isUrdu
                ? (causeData['ur'] ?? causeData['en'] ?? '')
                : (causeData['en'] ?? causeData['ur'] ?? '');
          } else {
            text = causeData.toString().trim();
          }
          if (text.isEmpty) return const SizedBox.shrink();

          final icons = [
            Icons.bug_report_outlined,
            Icons.water_drop_outlined,
            Icons.wb_sunny_outlined,
            Icons.thermostat_outlined,
            Icons.eco_outlined,
          ];
          final icon = icons[i % icons.length];
          final isLast = i == causes.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(
                height: 1, indent: 60,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ],
          );
        }),
      ),
    );
  }
}
