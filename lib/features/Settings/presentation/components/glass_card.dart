import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../../core/constants/app_measurements.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool useSolidBackground;

  const GlassCard({super.key, required this.child, this.useSolidBackground = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
        color: useSolidBackground ? Colors.white.withOpacity(1) : null,
        gradient: !useSolidBackground
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ]
              : [
            Colors.white.withOpacity(0.3),
            Colors.grey[200]!.withOpacity(0.2),
          ],
        )
            : null,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
        child: useSolidBackground
            ? child
            : BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }
}