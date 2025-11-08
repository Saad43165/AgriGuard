// lib/features/scan_history/presentation/components/recent_scans_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/glass_card.dart';
import 'scan_card.dart';

class RecentScansSection extends StatelessWidget {
  final List<Map<String, dynamic>> recentScans;
  final Animation<double> scaleAnimation;
  final void Function(String?) onDeleteScan;        // ← Fixed: void Function
  final VoidCallback onShowAllScans;
  final void Function(Map<String, dynamic>) onShowOptions; // ← Correct

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
    final padding = AppMeasurements.getResponsivePadding(context);

    if (recentScans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        GlassCard(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: padding * 1.2,
              vertical: padding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Recent Scans',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: AppMeasurements.getResponsiveFontSize(
                        context,
                        baseSize: 22,
                      ),
                    ),
                  ),
                ),
                _buildViewAllButton(context),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Horizontal List
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: padding),
            scrollDirection: Axis.horizontal,
            itemCount: recentScans.length,
            itemBuilder: (context, index) {
              final scan = recentScans[index];
              final scanId = scan['id']?.toString() ?? 'scan_$index';

              return Container(
                width: 160,
                margin: EdgeInsets.only(
                  right: index < recentScans.length - 1 ? 16 : 0,
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
                      onShowOptions: (scanData) => onShowOptions(scanData), // ← CORRECT
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
            Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onShowAllScans();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'View All',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}