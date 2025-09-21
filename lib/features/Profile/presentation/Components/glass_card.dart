import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../../../../../../core/constants/app_measurements.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool useSolidBackground;
  final double? borderRadius;
  final double? blur;
  final EdgeInsetsGeometry? padding;
  final double? elevation;

  const GlassCard({
    super.key,
    required this.child,
    this.useSolidBackground = false,
    this.borderRadius,
    this.blur,
    this.padding,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderRadius = borderRadius ?? AppMeasurements.getResponsiveBorderRadius(context);
    final effectiveBlur = blur ?? (isDarkMode ? 20.0 : 15.0); // Increased blur values
    final effectiveElevation = elevation ?? (isDarkMode ? 8.0 : 4.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200), // Smooth transition
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        color: useSolidBackground
            ? Theme.of(context).colorScheme.surface.withOpacity(isDarkMode ? 0.8 : 0.9)
            : null,
        gradient: !useSolidBackground
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            Theme.of(context).colorScheme.surface.withOpacity(0.3),
            Theme.of(context).colorScheme.surface.withOpacity(0.2),
          ]
              : [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.2),
          ],
        )
            : null,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(isDarkMode ? 0.2 : 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(isDarkMode ? 0.4 : 0.1),
            blurRadius: effectiveElevation * 2,
            spreadRadius: effectiveElevation / 4,
            offset: Offset(0, effectiveElevation / 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: Stack(
          children: [
            if (!useSolidBackground)
              BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: effectiveBlur,
                  sigmaY: effectiveBlur,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
              ),
            Padding(
              padding: padding ?? EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}