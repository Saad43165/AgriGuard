import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final String? subtitle;
  final Color? iconColor;
  final Color? backgroundColor;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
    this.subtitle,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final effectiveBgColor = backgroundColor ?? effectiveIconColor.withOpacity(0.15);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon Container with Gradient
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                effectiveBgColor,
                effectiveBgColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: effectiveIconColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: effectiveIconColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),

        // Title and Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 18,
                  ),
                  letterSpacing: -0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Trailing Widget
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}