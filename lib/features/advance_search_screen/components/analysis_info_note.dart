import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';

class AnalysisInfoNote extends StatelessWidget {
  const AnalysisInfoNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppMeasurements.getResponsivePadding(context);

    return Container(
      padding: EdgeInsets.all(padding * 0.7),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Analysis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Roboflow Custom AI uses your own trained RF-DETR model (fine-tuned on real-field leaf images) for accurate plant disease detection with bounding boxes. '
                      'Plant.id provides professional plant identification with disease diagnosis and treatment recommendations.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Roboflow: Best for real-world field conditions (free 10,000 inferences/month)\n'
                      '• Plant.id: Great for detailed treatment suggestions',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}