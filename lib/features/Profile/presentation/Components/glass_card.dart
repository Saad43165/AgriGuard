import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../../../../../../core/constants/app_measurements.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool useSolidBackground;
  final double? borderRadius;
  final double? blur;

  const GlassCard({
    super.key,
    required this.child,
    this.useSolidBackground = false,
    this.borderRadius,
    this.blur,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderRadius = borderRadius ?? AppMeasurements.getResponsiveBorderRadius(context);
    final effectiveBlur = blur ?? (isDarkMode ? 15.0 : 10.0); // Increased blur in dark mode

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        color: useSolidBackground ? Theme.of(context).colorScheme.surface.withOpacity(0.9) : null,
        gradient: !useSolidBackground
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.25), // Adjusted opacity
            Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
          ]
              : [
            Colors.white.withOpacity(0.35),
            Colors.grey[200]!.withOpacity(0.25),
          ],
        )
            : null,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(isDarkMode ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: useSolidBackground
            ? child
            : BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: child,
        ),
      ),
    );
  }
}