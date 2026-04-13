import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = (screenWidth * 0.025).clamp(8.0, 12.0);

    if (recentScans.isEmpty) {
      return const SizedBox.shrink();
    }

    // Dynamic color based on section type
    final sectionColor = showAdvancedBadge
        ? (isDark ? const Color(0xFF5E97F6) : const Color(0xFF4285F4))
        : Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Modern Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: Row(
            children: [
              // Icon with gradient
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: showAdvancedBadge
                        ? (isDark
                        ? [const Color(0xFF5E97F6), const Color(0xFF5BB974)]
                        : [const Color(0xFF4285F4), const Color(0xFF34A853)])
                        : [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: sectionColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  showAdvancedBadge ? Icons.cloud_outlined : Icons.smartphone_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Text(
                  sectionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              // View All Button
              _buildViewAllButton(context, isDark, sectionColor),
            ],
          ),
        ),

        SizedBox(height: screenHeight * 0.012),

        // Scans list — height accommodates image + info without overflow
        SizedBox(
          height: 170,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recentScans.length,
            itemBuilder: (context, index) {
              final scan = recentScans[index];
              final scanId = scan['id']?.toString() ?? 'scan_$index';
              // Card width: enough for image + text without overflow
              final cardWidth = (MediaQuery.of(context).size.width * 0.38).clamp(140.0, 160.0);

              return SizedBox(
                width: cardWidth,
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < recentScans.length - 1 ? 10 : 0,
                    left: index == 0 ? 4 : 0,
                  ),
                  child: ScanCard(
                    key: ValueKey('scan_card_$scanId'),
                    scan: scan,
                    index: index,
                    scaleAnimation: scaleAnimation,
                    onShowOptions: (scanData) => onShowOptions(scanData),
                    showFullPlantName: false,
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: screenHeight * 0.005),
      ],
    );
  }

  Widget _buildViewAllButton(BuildContext context, bool isDark, Color sectionColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          onShowAllScans();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                sectionColor.withValues(alpha: 0.2),
                sectionColor.withValues(alpha: 0.15),
              ]
                  : [
                sectionColor.withValues(alpha: 0.12),
                sectionColor.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? sectionColor.withValues(alpha: 0.4)
                  : sectionColor.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: TextStyle(
                  color: isDark ? sectionColor : sectionColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: isDark ? sectionColor : sectionColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}