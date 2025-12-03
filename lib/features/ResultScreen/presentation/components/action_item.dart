import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';

class ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap; // Now nullable
  final EdgeInsets? padding; // Use EdgeInsets, not String

  const ActionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled
            ? () {
          onTap?.call();
          HapticFeedback.lightImpact();
        }
            : null,
        child: Container(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: AppMeasurements.getResponsivePadding(context),
                vertical: 16,
              ),
          child: Row(
            children: [
              // Icon Container with Gradient Circle
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: enabled
                        ? [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.secondary.withOpacity(0.2),
                    ]
                        : [
                      theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                  size: AppMeasurements.getResponsiveIconSizeSmall(context),
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: enabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                        fontSize: AppMeasurements.getResponsiveFontSize(
                          context,
                          baseSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: enabled
                            ? theme.colorScheme.onSurface.withOpacity(0.7)
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                        fontSize: AppMeasurements.getResponsiveFontSize(
                          context,
                          baseSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Optional Chevron for enabled state
              if (enabled)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}