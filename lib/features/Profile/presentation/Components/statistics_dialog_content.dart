import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

class StatisticsDialogContent extends StatelessWidget {
  final Map<String, int> scansPerCrop;
  final DateTime lastScanDate;
  final Map<String, dynamic> userProfile;

  const StatisticsDialogContent({
    super.key,
    required this.scansPerCrop,
    required this.lastScanDate,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan Statistics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
            ),
          ),
          const SizedBox(height: AppMeasurements.defaultPadding),
          Text(
            'Total Scans: ${userProfile['scanCount']}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
            ),
          ),
          const SizedBox(height: AppMeasurements.smallPadding),
          ...scansPerCrop.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppMeasurements.smallPadding),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
          )),
          const SizedBox(height: AppMeasurements.smallPadding),
          Text(
            'Last Scan: ${lastScanDate.toString().substring(0, 10)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
            ),
          ),
          const SizedBox(height: AppMeasurements.defaultPadding),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}