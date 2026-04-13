import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

class FloatingOrb extends StatelessWidget {
  final int index;
  final double maxWidth;
  final AnimationController fadeController;
  final Animation<double> scaleAnimation;

  const FloatingOrb({
    super.key,
    required this.index,
    required this.maxWidth,
    required this.fadeController,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeController,
      builder: (context, child) {
        return Positioned(
          top: (index * 150.0) % MediaQuery.of(context).size.height,
          left: (index * 100.0) % maxWidth,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Container(
              width: AppMeasurements.getResponsiveSize(context, baseSize: 80 + (index * 20.0)),
              height: AppMeasurements.getResponsiveSize(context, baseSize: 80 + (index * 20.0)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}