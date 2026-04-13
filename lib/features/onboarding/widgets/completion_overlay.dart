import 'package:flutter/material.dart';
import 'dart:math' as math;

class CompletionOverlay extends StatelessWidget {
  final AnimationController controller;

  const CompletionOverlay({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Quick animations - completes in ~800ms total
        final scaleIn = controller.value < 0.4
            ? Curves.easeOutBack.transform(controller.value / 0.4)
            : 1.0;

        final fadeIn = controller.value < 0.4
            ? Curves.easeOut.transform(controller.value / 0.4)
            : 1.0;

        final fadeOut = controller.value > 0.6
            ? Curves.easeIn.transform((controller.value - 0.6) / 0.4)
            : 0.0;

        final opacity = fadeIn * (1 - fadeOut);
        final rippleScale = Curves.easeOut.transform(controller.value) * 3;

        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: 0.6 * opacity),
              child: Stack(
                children: [
                  // Expanding ripple effect
                  Center(
                    child: Transform.scale(
                      scale: rippleScale,
                      child: Opacity(
                        opacity: (1 - controller.value) * 0.3,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main success circle
                  Center(
                    child: Transform.scale(
                      scale: scaleIn,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            children: [
                              // Shine effect
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      center: Alignment.topLeft,
                                      radius: 1.5,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.5),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Check icon
                              Center(
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 300),
                                  tween: Tween(
                                    begin: 0.0,
                                    end: controller.value > 0.2 ? 1.0 : 0.0,
                                  ),
                                  builder: (context, checkValue, child) {
                                    return Transform.scale(
                                      scale: Curves.elasticOut.transform(checkValue),
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Success text
                  if (controller.value > 0.25)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 130),
                        child: Opacity(
                          opacity: opacity,
                          child: Text(
                            'Success!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Decorative particles (simple, performant)
                  ..._buildSimpleParticles(opacity),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSimpleParticles(double opacity) {
    return List.generate(6, (index) {
      final angle = (index * 2 * math.pi / 6);
      final progress = Curves.easeOut.transform(controller.value);
      final distance = 80 + (progress * 50);

      return Center(
        child: Transform.translate(
          offset: Offset(
            distance * math.cos(angle),
            distance * math.sin(angle),
          ),
          child: Opacity(
            opacity: opacity * (1 - controller.value),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
  }
}