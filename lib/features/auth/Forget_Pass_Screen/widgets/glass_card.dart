import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';

/// Glassmorphic card with blur + subtle gradient.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;   // optional padding (inside the blur)

  const GlassCard({
    super.key,
    required this.child,
    required this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface.withOpacity(0.12),
            surface.withOpacity(0.06),
          ],
        ),
        border: Border.all(color: surface.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.background.withOpacity(0.3),
            blurRadius: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}