import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/severity_indicator.dart';
import '../../../../../core/widgets/glass_card.dart';
import 'diagnosis_result.dart';


class DiagnosisCard extends StatelessWidget {
  final DiagnosisResult diagnosisResult;

  const DiagnosisCard({super.key, required this.diagnosisResult});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PLANT IDENTIFIED',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 1.2,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
            ),
            const SizedBox(height: AppMeasurements.smallPadding),

            // Show the plant name prominently
            Text(
              diagnosisResult.plantName, // This will show "Lily", "Tomato", etc.
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 24),
              ),
            ),

            const SizedBox(height: AppMeasurements.smallPadding),

            // Show the disease/diagnosis
            Text(
              diagnosisResult.disease,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppMeasurements.smallPadding),
            SeverityIndicator(severity: diagnosisResult.severity),
          ],
        ),
      ),
    );
  }
}