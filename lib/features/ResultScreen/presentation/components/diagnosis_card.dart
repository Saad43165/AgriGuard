import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/widgets/app_themes.dart';
import '../../../../../core/services/translation_service.dart';
import '../models/diagnosis_result.dart';

class DiagnosisCard extends StatelessWidget {
  final DiagnosisResult diagnosisResult;
  const DiagnosisCard({super.key, required this.diagnosisResult});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final textSub = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.biotech_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Diagnosis',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: textPrimary, letterSpacing: -0.3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 16),

            // Plant name row
            _InfoRow(
              icon: Icons.eco_rounded,
              iconColor: AppColors.success,
              label: t.get('plant_name'),
              value: t.translatePlant(diagnosisResult.plantName),
              isDark: isDark,
              textPrimary: textPrimary,
              textSub: textSub,
            ),

            const SizedBox(height: 14),

            // Disease row
            _InfoRow(
              icon: diagnosisResult.isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
              iconColor: diagnosisResult.isHealthy ? AppColors.success : AppColors.warning,
              label: 'Status',
              value: t.translateDisease(diagnosisResult.disease),
              valueColor: diagnosisResult.isHealthy ? AppColors.success : AppColors.warning,
              isDark: isDark,
              textPrimary: textPrimary,
              textSub: textSub,
            ),

            const SizedBox(height: 14),

            // Severity + confidence row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _severityColor(diagnosisResult.severity).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.speed_rounded, color: _severityColor(diagnosisResult.severity), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Severity', style: TextStyle(fontSize: 11, color: textSub, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _severityColor(diagnosisResult.severity),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              t.translateSeverity(diagnosisResult.severity),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${diagnosisResult.confidence}% confidence',
                            style: TextStyle(fontSize: 12, color: textSub, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (diagnosisResult.description != null && diagnosisResult.description!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Text(
                  diagnosisResult.description!,
                  style: TextStyle(fontSize: 13, color: textSub, height: 1.5),
                ),
              ),
            ],

            if (diagnosisResult.scientificName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.science_rounded, size: 14, color: textSub),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      diagnosisResult.scientificName!,
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSub),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _severityColor(String s) {
    switch (s.toLowerCase()) {
      case 'low': case 'mild':     return AppColors.info;
      case 'medium': case 'moderate': return AppColors.warning;
      case 'high': case 'severe':  return AppColors.error;
      case 'critical':             return const Color(0xFFDC2626);
      case 'none': case 'healthy': return AppColors.success;
      default:                     return AppColors.lightCaption;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;
  final Color textPrimary;
  final Color textSub;

  const _InfoRow({
    required this.icon, required this.iconColor,
    required this.label, required this.value,
    this.valueColor, required this.isDark,
    required this.textPrimary, required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: textSub, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: valueColor ?? textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
