import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.valueColor,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    Widget content = Row(
      children: [
        // Icon Container with Gradient
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                effectiveIconColor.withOpacity(0.2),
                effectiveIconColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: effectiveIconColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: effectiveIconColor,
            size: AppMeasurements.getResponsiveIconSizeSmall(context),
          ),
        ),
        const SizedBox(width: 14),

        // Label and Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 12,
                  ),
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Optional Chevron for tappable items
        if (onTap != null) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            size: 20,
          ),
        ],
      ],
    );

    // Wrap with InkWell if tappable
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: content,
    );
  }
}