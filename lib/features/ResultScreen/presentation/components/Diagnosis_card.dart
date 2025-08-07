import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/severity_indicator.dart';
import '../../../Profile/presentation/Components/glass_card.dart';
import '../screens/results_screen.dart';

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
              'PLANT DIAGNOSIS',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 1.2,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
            ),
            const SizedBox(height: AppMeasurements.smallPadding),
            Text(
              diagnosisResult.disease,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 24),
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