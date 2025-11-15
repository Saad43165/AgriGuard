// lib/features/scan_history/presentation/components/recent_scans_section.dart
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

  const RecentScansSection({
    super.key,
    required this.recentScans,
    required this.scaleAnimation,
    required this.onDeleteScan,
    required this.onShowAllScans,
    required this.onShowOptions,
  });

  @override
  Widget build(BuildContext context) {
    if (recentScans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Recent Scans',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 18,
                  ),
                  letterSpacing: -0.5,
                ),
              ),
              _buildViewAllButton(context),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Compact Horizontal List
        SizedBox(
          height: 140, // Reduced from 200
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recentScans.length,
            itemBuilder: (context, index) {
              final scan = recentScans[index];
              final scanId = scan['id']?.toString() ?? 'scan_$index';

              return Container(
                width: 130, // Reduced from 160
                margin: EdgeInsets.only(
                  right: index < recentScans.length - 1 ? 12 : 0,
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          onShowAllScans();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}