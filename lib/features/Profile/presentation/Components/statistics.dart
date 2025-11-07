import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_measurements.dart';
import '../../../../core/widgets/glass_card.dart';
import 'stat_item.dart';

class Statistics extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final EdgeInsets cardPadding;
  final double itemSpacing;

  const Statistics({
    super.key,
    required this.userProfile,
    required this.cardPadding,
    required this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final iconSize = AppMeasurements.getResponsiveIconSizeMedium(context);
    final fontSizeLarge = AppMeasurements.getResponsiveFontSize(context, baseSize: 18);
    final fontSizeSmall = AppMeasurements.getResponsiveFontSize(context, baseSize: 14);

    return GlassCard(
      child: Padding(
        padding: cardPadding,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(smallPadding),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                      ],
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
                        'Statistics',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: fontSizeLarge,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        userProfile['lastUpdated'] ?? 'N/A',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          fontSize: fontSizeSmall,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: itemSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatItem(
                  value: userProfile['scanCount'].toString(),
                  label: 'Scans',
                  icon: Icons.camera_alt_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Container(
                  width: 1,
                  height: AppMeasurements.getResponsiveHeight(context, baseHeight: 80),
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                ),
                StatItem(
                  value: userProfile['crops'].length.toString(),
                  label: 'Crops',
                  icon: Icons.eco_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
      padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: AppMeasurements.getResponsiveIconSizeMedium(context),
                ),
              ),
              SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      'Last Updated: ${TimeOfDay.fromDateTime(DateTime.now()).format(context)}, July 02, 2025',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context) * 1.5),
          Column(
            children: [
              Text(
                'Scan Breakdown',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                ),
              ),
              SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
              ...userProfile['crops'].map((crop) => Padding(
                padding: EdgeInsets.symmetric(vertical: AppMeasurements.getResponsiveSmallPadding(context) * 0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      crop,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    Text(
                      '${scansPerCrop[crop] ?? 0} Scans',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                      ),
                    ),
                  ],
                ),
              )).toList(),
              SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last Scan Date',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  Text(
                    '${lastScanDate.day}/${lastScanDate.month}/${lastScanDate.year}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
              ),
            ),
            child: Text(
              'Close',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}