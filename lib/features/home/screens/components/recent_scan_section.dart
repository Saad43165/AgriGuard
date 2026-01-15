import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_measurements.dart';
import 'scan_card.dart';

class RecentScansSection extends StatelessWidget {
  final List<Map<String, dynamic>> recentScans;
  final Animation<double> scaleAnimation;
  final void Function(String?) onDeleteScan;
  final VoidCallback onShowAllScans;
  final void Function(Map<String, dynamic>) onShowOptions;
  final String sectionTitle;
  final bool showAdvancedBadge;

  const RecentScansSection({
    super.key,
    required this.recentScans,
    required this.scaleAnimation,
    required this.onDeleteScan,
    required this.onShowAllScans,
    required this.onShowOptions,
    required this.sectionTitle,
    required this.showAdvancedBadge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (recentScans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header - REMOVED SCAN COUNT
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title with icon - WITHOUT COUNT
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getSectionColor(theme),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      showAdvancedBadge ? Icons.cloud : Icons.phone_android,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sectionTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppMeasurements.getResponsiveFontSize(
                        context,
                        baseSize: 18,
                      ),
                      letterSpacing: -0.3,
                    ),
                  ),
                  // REMOVED: Scan count container
                ],
              ),

              // View All Button
              _buildViewAllButton(context),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Horizontal Scans List
        SizedBox(
          height: 160,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recentScans.length,
            itemBuilder: (context, index) {
              final scan = recentScans[index];
              final scanId = scan['id']?.toString() ?? 'scan_$index';

              return Container(
                width: 140,
                margin: EdgeInsets.only(
                  right: index < recentScans.length - 1 ? 12 : 20,
                ),
                child: Hero(
                  tag: 'recent_scan_hero_$scanId',
                  flightShuttleBuilder: (_, animation, __, ___, toHeroContext) {
                    return ScaleTransition(
                      scale: animation,
                      child: toHeroContext.widget,
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: ScanCard(
                      key: ValueKey('scan_card_$scanId'),
                      scan: scan,
                      index: index,
                      scaleAnimation: scaleAnimation,
                      onShowOptions: (scanData) => onShowOptions(scanData),
                      showFullPlantName: false,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          onShowAllScans();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSectionColor(ThemeData theme) {
    if (showAdvancedBadge) {
      return Colors.blue;
    }
    return theme.colorScheme.primary;
  }
}