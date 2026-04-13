// lib/features/ResultScreen/presentation/components/results/additional_info_card.dart
import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_measurements.dart';

class AdditionalInfoCard extends StatelessWidget {
  final ThemeData theme;
  final String info;
  final bool hasDiseaseInfo;

  const AdditionalInfoCard({
    super.key,
    required this.theme,
    required this.info,
    required this.hasDiseaseInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        AppMeasurements.getResponsivePadding(context),
      ),
      decoration: BoxDecoration(
        color: hasDiseaseInfo ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        border: Border.all(
          color: hasDiseaseInfo ? Colors.green : Colors.orange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasDiseaseInfo ? Icons.medical_services : Icons.visibility,
                size: AppMeasurements.getResponsiveIconSizeSmall(context),
                color: hasDiseaseInfo ? Colors.green : Colors.orange,
              ),
              SizedBox(
                width: AppMeasurements.getResponsiveSmallPadding(context),
              ),
              Text(
                hasDiseaseInfo ? 'Disease Analysis' : 'Plant Identification',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hasDiseaseInfo ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(
            height: AppMeasurements.getResponsiveSmallPadding(context),
          ),
          Text(
            info,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
          if (!hasDiseaseInfo) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For disease detection, upload clear photos of affected leaves.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}