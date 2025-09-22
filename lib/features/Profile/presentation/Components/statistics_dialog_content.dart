import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_measurements.dart';
import 'glass_card.dart';

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
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final mediumPadding = AppMeasurements.getResponsivePadding(context);
    final iconSize = AppMeasurements.getResponsiveIconSizeMedium(context);
    final fontSizeLarge = AppMeasurements.getResponsiveFontSize(context, baseSize: 20);
    final fontSizeMedium = AppMeasurements.getResponsiveFontSize(context, baseSize: 16);
    final fontSizeSmall = AppMeasurements.getResponsiveFontSize(context, baseSize: 14);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        useSolidBackground: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppMeasurements.getResponsiveWidth(context, baseWidth: 420),
            maxHeight: AppMeasurements.getResponsiveHeight(context, baseHeight: 650),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(mediumPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(smallPadding),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.analytics_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: smallPadding),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detailed Statistics',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: fontSizeLarge,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              'Last Updated: ${TimeOfDay.fromDateTime(DateTime.now()).format(context)}, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                fontSize: fontSizeSmall,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          size: iconSize,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                          padding: EdgeInsets.all(smallPadding * 0.5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: mediumPadding),

                  // Scan Breakdown Section
                  Container(
                    padding: EdgeInsets.all(mediumPadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Breakdown',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: fontSizeMedium,
                          ),
                        ),
                        SizedBox(height: smallPadding),
                        if (userProfile['crops'].isEmpty)
                          _buildEmptyState(context)
                        else
                          ...userProfile['crops'].map<Widget>((crop) => Padding(
                            padding: EdgeInsets.symmetric(vertical: smallPadding * 0.5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getCropIcon(crop),
                                      size: fontSizeSmall,
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                    ),
                                    SizedBox(width: smallPadding * 0.5),
                                    Text(
                                      crop,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: fontSizeMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${scansPerCrop[crop] ?? 0} Scans',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontSize: fontSizeMedium,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      ],
                    ),
                  ),
                  SizedBox(height: mediumPadding),

                  // Last Scan Date
                  Container(
                    padding: EdgeInsets.all(mediumPadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: fontSizeSmall,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            ),
                            SizedBox(width: smallPadding * 0.5),
                            Text(
                              'Last Scan Date',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: fontSizeMedium,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${lastScanDate.day}/${lastScanDate.month}/${lastScanDate.year}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: fontSizeMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: mediumPadding),

                  // Close Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: mediumPadding * 2,
                          vertical: smallPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: fontSizeMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final fontSizeMedium = AppMeasurements.getResponsiveFontSize(context, baseSize: 16);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);

    return Container(
      padding: EdgeInsets.all(smallPadding * 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.agriculture_rounded,
            size: AppMeasurements.getResponsiveIconSizeLarge(context),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          SizedBox(height: smallPadding),
          Text(
            'No Scans Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: fontSizeMedium,
            ),
          ),
          SizedBox(height: smallPadding * 0.5),
          Text(
            'Start scanning crops to see detailed statistics here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: fontSizeMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getCropIcon(String cropType) {
    switch (cropType.toLowerCase()) {
      case 'wheat':
        return Icons.grass_rounded;
      case 'cotton':
        return Icons.local_florist_rounded;
      case 'rice':
        return Icons.water_drop_rounded;
      case 'corn':
        return Icons.eco_rounded;
      case 'sugarcane':
        return Icons.forest_rounded;
      default:
        return Icons.agriculture_rounded;
    }
  }
}