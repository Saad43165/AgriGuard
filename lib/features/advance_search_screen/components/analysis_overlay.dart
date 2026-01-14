// lib/features/ResultScreen/presentation/components/analysis_overlay.dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

class AnalysisOverlay extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> selectedOption;

  const AnalysisOverlay({
    super.key,
    required this.theme,
    required this.selectedOption,
  });

  @override
  Widget build(BuildContext context) {
    final isPlantId = selectedOption['type'] == 'PlantId';

    return Container(
      color: Colors.black87,
      child: Center(
        child: Card(
          margin: EdgeInsets.all(
            AppMeasurements.getResponsivePadding(context),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(
              AppMeasurements.getResponsivePadding(context) * 1.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
                SizedBox(
                  height: AppMeasurements.getResponsivePadding(context),
                ),
                Text(
                  'Analyzing with ${selectedOption['title']}...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppMeasurements.getResponsiveSmallPadding(context),
                ),
                Text(
                  isPlantId
                      ? 'Using Plant.id AI for real plant identification'
                      : 'Using Google Gemini AI for detailed analysis',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      isPlantId ? 'REAL PLANT.ID AI' : 'REAL GEMINI AI',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}