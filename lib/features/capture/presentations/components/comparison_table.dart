import 'package:flutter/material.dart';
import 'dart:ui';

class ComparisonTable extends StatelessWidget {
  const ComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            const Color(0xFF1E1E2E),
            const Color(0xFF16213E),
          ]
              : [
            Colors.white,
            const Color(0xFFF8F9FF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.compare_arrows_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Method Comparison',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            'Choose what suits you best',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Method Headers
                _buildMethodHeaders(context, isDark),

                const SizedBox(height: 16),

                // Comparison Rows
                _buildComparisonRow(
                  context,
                  icon: Icons.wifi_off_rounded,
                  feature: 'Internet',
                  onDevice: 'Not Required',
                  onDevicePositive: true,
                  cloudAI: 'Required',
                  cloudAIPositive: false,
                  isDark: isDark,
                ),

                const SizedBox(height: 10),

                _buildComparisonRow(
                  context,
                  icon: Icons.flash_on_rounded,
                  feature: 'Speed',
                  onDevice: 'Instant',
                  onDevicePositive: true,
                  cloudAI: '10-30s',
                  cloudAIPositive: false,
                  isDark: isDark,
                ),

                const SizedBox(height: 10),

                _buildComparisonRow(
                  context,
                  icon: Icons.eco_rounded,
                  feature: 'Database',
                  onDevice: '12 Species',
                  onDevicePositive: false,
                  cloudAI: '50,000+',
                  cloudAIPositive: true,
                  isDark: isDark,
                ),

                const SizedBox(height: 10),

                _buildComparisonRow(
                  context,
                  icon: Icons.lock_rounded,
                  feature: 'Privacy',
                  onDevice: '100% Private',
                  onDevicePositive: true,
                  cloudAI: 'Cloud Based',
                  cloudAIPositive: false,
                  isDark: isDark,
                ),

                const SizedBox(height: 10),

                _buildComparisonRow(
                  context,
                  icon: Icons.star_rounded,
                  feature: 'Best For',
                  onDevice: 'Quick Checks',
                  onDevicePositive: null,
                  cloudAI: 'Deep Analysis',
                  cloudAIPositive: null,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodHeaders(BuildContext context, bool isDark) {
    return Row(
      children: [
        const SizedBox(width: 80), // Reduced from 100 for more space
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00B4DB),
                  Color(0xFF0083B0),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B4DB).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.phone_android_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(height: 4),
                const Text(
                  'On-Device',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'TFLite',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6A11CB),
                  Color(0xFF2575FC),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A11CB).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cloud AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Plant.id',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(
      BuildContext context, {
        required IconData icon,
        required String feature,
        required String onDevice,
        required bool? onDevicePositive,
        required String cloudAI,
        required bool? cloudAIPositive,
        required bool isDark,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
        ),
      ),
      child: Row(
        children: [
          // Feature Icon & Name (reduced width)
          SizedBox(
            width: 80,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 13,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    feature,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // On-Device Value
          Expanded(
            child: _buildValueChip(
              context,
              value: onDevice,
              isPositive: onDevicePositive,
              baseColor: const Color(0xFF00B4DB),
              isDark: isDark,
            ),
          ),

          const SizedBox(width: 6),

          // Cloud AI Value
          Expanded(
            child: _buildValueChip(
              context,
              value: cloudAI,
              isPositive: cloudAIPositive,
              baseColor: const Color(0xFF6A11CB),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueChip(
      BuildContext context, {
        required String value,
        required bool? isPositive,
        required Color baseColor,
        required bool isDark,
      }) {
    Color bgColor;
    Color textColor;
    Color borderColor;
    IconData? icon;

    if (isPositive == null) {
      // Neutral
      bgColor = baseColor.withOpacity(0.12);
      textColor = isDark ? Colors.white : baseColor;
      borderColor = baseColor.withOpacity(0.25);
    } else if (isPositive) {
      // Positive - Green tint
      bgColor = const Color(0xFF10B981).withOpacity(0.15);
      textColor = isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
      borderColor = const Color(0xFF10B981).withOpacity(0.3);
      icon = Icons.check_circle_rounded;
    } else {
      // Negative - Orange tint
      bgColor = const Color(0xFFFF9800).withOpacity(0.15);
      textColor = isDark ? const Color(0xFFFF9800) : const Color(0xFFF57C00);
      borderColor = const Color(0xFFFF9800).withOpacity(0.3);
      icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 11,
              color: textColor,
            ),
          if (icon != null) const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.1,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}