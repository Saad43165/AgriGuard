import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/widgets/app_themes.dart';
import '../../../../../core/services/translation_service.dart';
import '../models/diagnosis_result.dart';

/// Botanical-style diagnosis card — clean white card, large plant name,
/// green subtitle, pill chips for severity/confidence.
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

    final severityColor = _severityColor(diagnosisResult.severity);
    final confidenceValue = double.tryParse(diagnosisResult.confidence) ?? 0.0;
    final isHealthy = diagnosisResult.isHealthy;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant name — large bold like reference app
          Text(
            t.translatePlant(diagnosisResult.plantName),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),

          // Disease — green if healthy, red if diseased
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: isHealthy ? AppColors.primary : severityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t.translateDisease(diagnosisResult.disease),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isHealthy ? AppColors.primary : severityColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info chips — pill style like reference app
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Severity chip
              _InfoChip(
                icon: isHealthy ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                label: t.translateSeverity(diagnosisResult.severity),
                color: severityColor,
                isDark: isDark,
              ),
              // Confidence chip
              _InfoChip(
                icon: Icons.analytics_outlined,
                label: '${confidenceValue.toStringAsFixed(0)}% ${t.get('ai_confidence')}',
                color: _confidenceColor(confidenceValue),
                isDark: isDark,
              ),
              // Scientific name chip if available
              if (diagnosisResult.scientificName != null)
                _InfoChip(
                  icon: Icons.science_outlined,
                  label: diagnosisResult.scientificName!,
                  color: textSub,
                  isDark: isDark,
                  italic: true,
                ),
            ],
          ),

          // Confidence bar
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (confidenceValue / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(_confidenceColor(confidenceValue)),
            ),
          ),

          // Description
          if (diagnosisResult.description != null &&
              diagnosisResult.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              diagnosisResult.description!,
              style: TextStyle(fontSize: 13, color: textSub, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Color _severityColor(String s) {
    switch (s.toLowerCase()) {
      case 'low': case 'mild': return AppColors.secondary;
      case 'medium': case 'moderate': return AppColors.warning;
      case 'high': case 'severe': return AppColors.error;
      case 'critical': return const Color(0xFFDC2626);
      case 'none': case 'healthy': return AppColors.primary;
      default: return AppColors.lightCaption;
    }
  }

  Color _confidenceColor(double v) {
    if (v >= 70) return AppColors.primary;
    if (v >= 45) return AppColors.warning;
    return AppColors.error;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool italic;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : const Color(0xFFE8E8E8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}
