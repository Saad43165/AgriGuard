import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/severity_indicator.dart';
import 'diagnosis_result.dart';

class DiagnosisCard extends StatelessWidget {
  final DiagnosisResult diagnosisResult;

  const DiagnosisCard({super.key, required this.diagnosisResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Helper methods inside build where theme is available
    Color _getDiseaseColor(DiagnosisResult result) {
      if (result.isHealthy) return Colors.green;
      if (result.requiresUrgentAction) return Colors.red;
      if (result.severity.toLowerCase() == 'medium') return Colors.orange;
      if (result.severity.toLowerCase() == 'low') return Colors.blue;
      return theme.colorScheme.error;
    }

    IconData _getDiseaseIcon(DiagnosisResult result) {
      if (result.isHealthy) return Icons.check_circle_rounded;
      if (result.requiresUrgentAction) return Icons.warning_rounded;
      if (result.severity.toLowerCase() == 'medium') return Icons.info_rounded;
      return Icons.warning_amber_rounded;
    }

    String _getDiseaseLabel(DiagnosisResult result) {
      if (result.isHealthy) return 'Health Status';
      if (result.severity.toLowerCase() == 'high') return 'Critical Condition';
      if (result.severity.toLowerCase() == 'medium') return 'Moderate Condition';
      return 'Detected Condition';
    }

    Color _getConfidenceColor(String confidence) {
      try {
        final conf = double.tryParse(confidence) ?? 0;
        if (conf >= 80) return Colors.green;
        if (conf >= 60) return Colors.orange;
        return Colors.red;
      } catch (e) {
        return Colors.grey;
      }
    }

    // Determine UI elements based on disease and severity
    final Color diseaseColor = _getDiseaseColor(diagnosisResult);
    final IconData diseaseIcon = _getDiseaseIcon(diagnosisResult);
    final String diseaseLabel = _getDiseaseLabel(diagnosisResult);
    final String confidenceText = '${diagnosisResult.confidence}% Confidence';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            diseaseColor.withOpacity(0.15),
            theme.colorScheme.surface.withOpacity(0.5),
          ]
              : [
            diseaseColor.withOpacity(0.08),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: diseaseColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: diseaseColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with plant verification and confidence
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'PLANT IDENTIFIED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(diagnosisResult.confidence).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getConfidenceColor(diagnosisResult.confidence).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        size: 14,
                        color: _getConfidenceColor(diagnosisResult.confidence),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        confidenceText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getConfidenceColor(diagnosisResult.confidence),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Plant Name Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plant Species',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        diagnosisResult.plantName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: AppMeasurements.getResponsiveFontSize(
                            context,
                            baseSize: 24,
                          ),
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (diagnosisResult.scientificName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            diagnosisResult.scientificName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.outline.withOpacity(0.0),
                    theme.colorScheme.outline.withOpacity(0.3),
                    theme.colorScheme.outline.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Disease Detection Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: diseaseColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    diseaseIcon,
                    color: diseaseColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diseaseLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        diagnosisResult.disease,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          fontSize: 20,
                          height: 1.3,
                        ),
                      ),
                      if (diagnosisResult.description != null && diagnosisResult.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            diagnosisResult.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Severity Indicator
            SeverityIndicator(
              severity: diagnosisResult.severity,
              showLabel: true,
              showDescription: true,
            ),
          ],
        ),
      ),
    );
  }
}