import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';

class ActionItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showChevron;

  const ActionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.padding,
    this.iconColor,
    this.backgroundColor,
    this.showChevron = true,
  });

  @override
  State<ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<ActionItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onTap != null;
    final effectiveIconColor = widget.iconColor ?? theme.colorScheme.primary;
    final effectiveBgColor = widget.backgroundColor ?? effectiveIconColor.withOpacity(0.15);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.title,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _controller.forward() : null,
        onTapUp: enabled
            ? (_) {
          _controller.reverse();
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        }
            : null,
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: enabled
                  ? () {
                HapticFeedback.lightImpact();
                widget.onTap?.call();
              }
                  : null,
              child: Container(
                padding: widget.padding ??
                    EdgeInsets.symmetric(
                      horizontal: AppMeasurements.getResponsivePadding(context),
                      vertical: 16,
                    ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon Container with Gradient
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: enabled
                              ? [
                            effectiveBgColor,
                            effectiveBgColor.withOpacity(0.7),
                          ]
                              : [
                            theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: enabled
                              ? effectiveIconColor.withOpacity(0.3)
                              : theme.colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: enabled
                            ? effectiveIconColor
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
                            widget.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: enabled
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                              fontSize: AppMeasurements.getResponsiveFontSize(
                                context,
                                baseSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: enabled
                                  ? theme.colorScheme.onSurface.withOpacity(0.7)
                                  : theme.colorScheme.onSurface.withOpacity(0.4),
                              fontSize: AppMeasurements.getResponsiveFontSize(
                                context,
                                baseSize: 13,
                              ),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chevron for enabled state
                    if (enabled && widget.showChevron) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}