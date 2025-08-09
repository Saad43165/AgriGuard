import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../Profile/presentation/Components/glass_card.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateFormatter = DateFormat('MMMM d, yyyy'); // Format: August 9, 2025

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
      ),
      child: Stack(
        children: [
          GlassCard(
            borderRadius: AppMeasurements.getResponsiveBorderRadius(context),
            blur: isDarkMode ? 15.0 : 10.0,
            child: Padding(
              padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Statistics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
                    ),
                  ),
                  SizedBox(height: AppMeasurements.getResponsivePadding(context)),
                  Semantics(
                    label: 'Total scans: ${userProfile['scanCount'] ?? 0}',
                    child: Text(
                      'Total Scans: ${userProfile['scanCount'] ?? 0}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
                  if (scansPerCrop.isEmpty)
                    Semantics(
                      label: 'No crop scans available',
                      child: Text(
                        'No crop scans available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                        ),
                      ),
                    )
                  else
                    ...scansPerCrop.entries.map((entry) => Semantics(
                      label: '${entry.key}: ${entry.value} scans',
                      child: Padding(
                        padding: EdgeInsets.only(bottom: AppMeasurements.getResponsiveSmallPadding(context)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(isDarkMode ? 0.2 : 0.8),
                            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppMeasurements.getResponsiveSmallPadding(context),
                            vertical: AppMeasurements.getResponsiveSmallPadding(context) * 0.5,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.grass_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                              ),
                              SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
                              Expanded(
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
                  Semantics(
                    label: 'Last scan date: ${dateFormatter.format(lastScanDate)}',
                    child: Text(
                      'Last Scan: ${dateFormatter.format(lastScanDate)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: AppMeasurements.getResponsivePadding(context)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                        ),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: AppMeasurements.getResponsivePadding(context) / 2,
            top: AppMeasurements.getResponsivePadding(context) / 2,
            child: Semantics(
              label: 'Close dialog',
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}