// lib/features/ResultScreen/presentation/components/results/diagnosis_card.dart
import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_measurements.dart';
import 'info_chip.dart';

typedef SeverityColorGetter = Color Function(String severity);

class DiagnosisCard extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> data;
  final SeverityColorGetter getSeverityColor;

  const DiagnosisCard({
    super.key,
    required this.theme,
    required this.data,
    required this.getSeverityColor,
  });

  @override
  Widget build(BuildContext context) {
    final severity = data['severity'] as String? ?? 'Unknown';
    final plantName = data['plantName'] as String? ?? 'Unknown';
    final diseaseName = data['diseaseName'] as String? ?? 'Unknown';

    // Handle confidence value
    String confidenceText = '0%';
    final confidenceValue = data['confidence'];
    if (confidenceValue is int) {
      confidenceText = '$confidenceValue%';
    } else if (confidenceValue is double) {
      confidenceText = '${confidenceValue.round()}%';
    } else if (confidenceValue is String) {
      try {
        final parsed = int.tryParse(confidenceValue);
        confidenceText = parsed != null ? '$parsed%' : '$confidenceValue%';
      } catch (_) {
        confidenceText = '$confidenceValue%';
      }
    }

    return Container(
      padding: EdgeInsets.all(
        AppMeasurements.getResponsivePadding(context),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            getSeverityColor(severity).withOpacity(0.15),
            getSeverityColor(severity).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        border: Border.all(
          color: getSeverityColor(severity).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  AppMeasurements.getResponsiveSmallPadding(context) * 0.8,
                ),
                decoration: BoxDecoration(
                  color: getSeverityColor(severity).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.biotech_rounded,
                  color: getSeverityColor(severity),
                  size: AppMeasurements.getResponsiveIconSize(context),
                ),
              ),
              SizedBox(
                width: AppMeasurements.getResponsiveSmallPadding(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plantName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      diseaseName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: getSeverityColor(severity),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppMeasurements.getResponsivePadding(context)),

          Row(
            children: [
              Expanded(
                child: InfoChip(
                  theme: theme,
                  label: 'Severity',
                  value: severity,
                  icon: Icons.warning_amber_rounded,
                  color: getSeverityColor(severity),
                ),
              ),
              SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
              Expanded(
                child: InfoChip(
                  theme: theme,
                  label: 'Confidence',
                  value: confidenceText,
                  icon: Icons.percent_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}