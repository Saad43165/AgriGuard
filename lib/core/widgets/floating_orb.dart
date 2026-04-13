import 'package:flutter/material.dart';

/// Subtle ambient background orb — purely decorative.
/// Kept very low opacity so it doesn't compete with content.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Only show orbs in dark mode — in light mode they make backgrounds muddy
    if (!isDark) return const SizedBox.shrink();

    final size = 120.0 + (index % 3) * 60.0;
    final top  = (index * 180.0) % (MediaQuery.of(context).size.height * 0.8);
    final left = (index * 130.0) % (maxWidth - size);

    return Positioned(
      top: top,
      left: left.clamp(0.0, maxWidth - size),
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: fadeController,
          builder: (_, __) => Opacity(
            opacity: fadeController.value * 0.6,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.04),
                    Colors.transparent,
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
