import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_measurements.dart';
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
    return Container(
      padding: EdgeInsets.all(AppMeasurements.smallPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  AppMeasurements.getResponsiveSmallPadding(context),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: AppMeasurements.getResponsiveIconSizeMedium(context),
                ),
              ),
              SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${userProfile['premiumScans'] ?? 0} premium • ${userProfile['savedPlants'] ?? 0} saved',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppMeasurements.smallPadding),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          SizedBox(height: AppMeasurements.smallPadding),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: StatItem(
                  value: userProfile['scanCount'].toString(),
                  label: 'Scans',
                  icon: Icons.camera_alt_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatItem(
                  value: userProfile['crops'].length.toString(),
                  label: 'Crops',
                  icon: Icons.eco_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppMeasurements.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppMeasurements.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    AppMeasurements.getResponsiveSmallPadding(context),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: AppMeasurements.getResponsiveIconSizeMedium(context),
                  ),
                ),
                SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detailed Statistics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Last Updated: ${TimeOfDay.fromDateTime(DateTime.now()).format(context)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppMeasurements.defaultPadding),

            // Scan Breakdown Section
            Container(
              padding: EdgeInsets.all(AppMeasurements.smallPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  AppMeasurements.getResponsiveBorderRadius(context),
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pie_chart_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scan Breakdown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
                  ...userProfile['crops'].map<Widget>((crop) => Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppMeasurements.getResponsiveExtraSmallPadding(context),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              crop,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${scansPerCrop[crop] ?? 0} Scans',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 13),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),

                  SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),

                  Container(
                    padding: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context)),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Last Scan Date',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${lastScanDate.day}/${lastScanDate.month}/${lastScanDate.year}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppMeasurements.defaultPadding),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: AppMeasurements.smallPadding,
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppMeasurements.getResponsiveBorderRadius(context),
                    ),
                  ),
                ).copyWith(
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      AppMeasurements.getResponsiveBorderRadius(context),
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(
                      vertical: AppMeasurements.smallPadding,
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}