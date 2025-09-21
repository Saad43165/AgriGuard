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
    final effectiveBlur = blur ?? (isDarkMode ? 20.0 : 15.0); // Increased blur for better glass effect

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        color: useSolidBackground ? Theme.of(context).colorScheme.surface.withOpacity(0.95) : null,
        gradient: !useSolidBackground
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            Theme.of(context).colorScheme.surface.withOpacity(0.4), // Better opacity for dark mode
            Theme.of(context).colorScheme.surface.withOpacity(0.2),
          ]
              : [
            Colors.white.withOpacity(0.7), // Increased opacity for better visibility
            Colors.white.withOpacity(0.4),
          ],
        )
            : null,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(isDarkMode ? 0.2 : 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDarkMode 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Theme.of(context).colorScheme.primary.withOpacity(0.02),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
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