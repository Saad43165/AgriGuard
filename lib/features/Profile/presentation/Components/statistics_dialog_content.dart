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
            blur: isDarkMode ? 20.0 : 15.0, // Enhanced blur for better glass effect
            child: Padding(
              padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context) * 0.75),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.analytics_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: AppMeasurements.getResponsiveFontSize(context, baseSize: 24),
                        ),
                      ),
                      SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
                      Expanded(
                        child: Text(
                          'Scan Statistics',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppMeasurements.getResponsivePadding(context)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [
                                Theme.of(context).colorScheme.surface.withOpacity(0.3),
                                Theme.of(context).colorScheme.surface.withOpacity(0.1),
                              ]
                            : [
                                Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
                          ),
                        ),
                        SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
                        Expanded(
                          child: Semantics(
                            label: 'Total scans: ${userProfile['scanCount'] ?? 0}',
                            child: Text(
                              'Total Scans: ${userProfile['scanCount'] ?? 0}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
                  if (scansPerCrop.isEmpty)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [
                                  Theme.of(context).colorScheme.surface.withOpacity(0.2),
                                  Theme.of(context).colorScheme.surface.withOpacity(0.1),
                                ]
                              : [
                                  Colors.grey[50]!.withOpacity(0.8),
                                  Colors.grey[100]!.withOpacity(0.6),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              size: AppMeasurements.getResponsiveFontSize(context, baseSize: 32),
                            ),
                            SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
                            Semantics(
                              label: 'No crop scans available',
                              child: Text(
                                'No crop scans available',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...scansPerCrop.entries.map((entry) => Semantics(
                      label: '${entry.key}: ${entry.value} scans',
                      child: Padding(
                        padding: EdgeInsets.only(bottom: AppMeasurements.getResponsiveSmallPadding(context)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkMode
                                  ? [
                                      Theme.of(context).colorScheme.surface.withOpacity(0.4),
                                      Theme.of(context).colorScheme.surface.withOpacity(0.2),
                                    ]
                                  : [
                                      Colors.white.withOpacity(0.8),
                                      Colors.white.withOpacity(0.6),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(isDarkMode ? 0.15 : 0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppMeasurements.getResponsiveSmallPadding(context),
                            vertical: AppMeasurements.getResponsiveSmallPadding(context) * 0.75,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.grass_rounded,
                                  color: Theme.of(context).colorScheme.secondary,
                                  size: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                ),
                              ),
                              SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
                              Expanded(
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 15),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [
                                Theme.of(context).colorScheme.surface.withOpacity(0.25),
                                Theme.of(context).colorScheme.surface.withOpacity(0.1),
                              ]
                            : [
                                Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.schedule_rounded,
                            color: Theme.of(context).colorScheme.secondary,
                            size: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                          ),
                        ),
                        SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
                        Expanded(
                          child: Semantics(
                            label: 'Last scan date: ${dateFormatter.format(lastScanDate)}',
                            child: Text(
                              'Last Scan: ${dateFormatter.format(lastScanDate)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppMeasurements.getResponsivePadding(context)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: isDarkMode 
                              ? Colors.black 
                              : Colors.white,
                          elevation: 8,
                          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context) * 1.5),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: AppMeasurements.getResponsiveSmallPadding(context),
                            horizontal: AppMeasurements.getResponsivePadding(context),
                          ),
                          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Theme.of(context).colorScheme.onPrimary.withOpacity(0.2);
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return Theme.of(context).colorScheme.onPrimary.withOpacity(0.1);
                              }
                              return null;
                            },
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                            ),
                            SizedBox(width: AppMeasurements.getResponsiveExtraSmallPadding(context)),
                            const Text('OK'),
                          ],
                        ),
                      ),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(AppMeasurements.getResponsiveExtraSmallPadding(context)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.error.withOpacity(0.2),
                        Theme.of(context).colorScheme.error.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
                    color: Theme.of(context).colorScheme.error,
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