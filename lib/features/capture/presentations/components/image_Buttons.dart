import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

class ImageButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isEnabled;
  final VoidCallback onPressed;

  const ImageButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<ImageButton> createState() => _ImageButtonState();
}

class _ImageButtonState extends State<ImageButton> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late AnimationController _glowController;
  late AnimationController _rippleController;
  late AnimationController _particleController;

  bool _isHovered = false;
  bool _isPressed = false;
  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();

    // Sophisticated hover animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Press feedback animation
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Continuous glow effect for primary button
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Ripple effect on tap
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Particle burst effect
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    _glowController.dispose();
    _rippleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;

    setState(() {
      _isPressed = true;
      _tapPosition = details.localPosition;
    });
    _pressController.forward();
    _rippleController.forward(from: 0.0);
  }

  void _handleTapUp() {
    if (!widget.isEnabled) return;

    setState(() => _isPressed = false);
    _pressController.reverse();
    _particleController.forward(from: 0.0);
    widget.onPressed();
  }

  void _handleTapCancel() {
    if (!widget.isEnabled) return;

    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!widget.isEnabled) return;
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        if (!widget.isEnabled) return;
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hoverController,
            _pressController,
            _glowController,
            _rippleController,
            _particleController,
          ]),
          builder: (context, child) {
            final hoverValue = _hoverController.value;
            final pressValue = _pressController.value;
            final scale = 1.0 - (pressValue * 0.05) + (hoverValue * 0.05);

            return Transform.scale(
              scale: scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  vertical: 16 + (hoverValue * 2),
                  horizontal: 12 + (hoverValue * 4),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20 + (hoverValue * 4)),
                  gradient: widget.isPrimary
                      ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(
                        0.15 + (hoverValue * 0.15),
                      ),
                      Theme.of(context).colorScheme.secondary.withOpacity(
                        0.15 + (hoverValue * 0.15),
                      ),
                      Theme.of(context).colorScheme.tertiary.withOpacity(
                        0.1 + (hoverValue * 0.1),
                      ),
                    ],
                  )
                      : LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface.withOpacity(
                        0.8 + (hoverValue * 0.1),
                      ),
                    ],
                  ),
                  border: Border.all(
                    color: widget.isPrimary
                        ? Theme.of(context).colorScheme.primary.withOpacity(
                      0.3 + (hoverValue * 0.3),
                    )
                        : Theme.of(context).colorScheme.outline.withOpacity(
                      0.2 + (hoverValue * 0.2),
                    ),
                    width: 1.5 + (hoverValue * 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isPrimary
                          ? Theme.of(context).colorScheme.primary.withOpacity(
                        0.1 + (_glowController.value * 0.2),
                      )
                          : Colors.black.withOpacity(0.03 + (hoverValue * 0.05)),
                      blurRadius: 8 + (hoverValue * 12) + (_glowController.value * 8),
                      spreadRadius: hoverValue * 2,
                      offset: Offset(0, 2 + (hoverValue * 4)),
                    ),
                    if (widget.isPrimary)
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(
                          0.05 + (_glowController.value * 0.1),
                        ),
                        blurRadius: 20 + (_glowController.value * 10),
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ripple effect
                    if (_rippleController.isAnimating)
                      CustomPaint(
                        painter: RipplePainter(
                          animation: _rippleController,
                          color: Theme.of(context).colorScheme.primary,
                          center: _tapPosition,
                        ),
                      ),

                    // Particle burst effect
                    if (_particleController.isAnimating)
                      CustomPaint(
                        painter: ParticleBurstPainter(
                          animation: _particleController,
                          color: widget.isPrimary
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          center: _tapPosition,
                        ),
                      ),

                    // Main content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Enhanced icon with 3D effect
                        Transform.translate(
                          offset: Offset(0, -hoverValue * 4),
                          child: Transform.rotate(
                            angle: hoverValue * 0.1,
                            child: Container(
                              padding: EdgeInsets.all(12 + (hoverValue * 4)),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: widget.isPrimary
                                    ? SweepGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                    Theme.of(context).colorScheme.tertiary,
                                    Theme.of(context).colorScheme.primary,
                                  ],
                                  stops: [0.0, 0.33, 0.66, 1.0],
                                  transform: GradientRotation(
                                    _glowController.value * 6.28,
                                  ),
                                )
                                    : null,
                                color: widget.isPrimary
                                    ? null
                                    : Theme.of(context).colorScheme.primaryContainer.withOpacity(
                                  0.3 + (hoverValue * 0.2),
                                ),
                                boxShadow: widget.isPrimary
                                    ? [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(
                                      0.3 + (_glowController.value * 0.3),
                                    ),
                                    blurRadius: 8 + (_glowController.value * 12),
                                    spreadRadius: 2 + (_glowController.value * 2),
                                    offset: Offset(0, 2 + (hoverValue * 2)),
                                  ),
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(
                                      0.2 + (_glowController.value * 0.2),
                                    ),
                                    blurRadius: 16 + (_glowController.value * 8),
                                    spreadRadius: 4,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                    : null,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: widget.isPrimary ? const EdgeInsets.all(2) : null,
                                decoration: widget.isPrimary
                                    ? BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  shape: BoxShape.circle,
                                )
                                    : null,
                                child: Icon(
                                  widget.icon,
                                  size: (AppMeasurements.getResponsiveIconSizeMedium(context) * 0.8) +
                                      (hoverValue * 6),
                                  color: widget.isPrimary
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 8 + (hoverValue * 2)),

                        // Enhanced label with shimmer effect
                        ShaderMask(
                          shaderCallback: (bounds) => widget.isPrimary && _isHovered
                              ? LinearGradient(
                            begin: Alignment(-1.0 + (_glowController.value * 3), 0),
                            end: Alignment(0.0 + (_glowController.value * 3), 0),
                            colors: [
                              Theme.of(context).colorScheme.onSurface,
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.onSurface,
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ).createShader(bounds)
                              : LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.onSurface,
                              Theme.of(context).colorScheme.onSurface,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            widget.label,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: AppMeasurements.getResponsiveFontSize(
                                context,
                                baseSize: 13,
                              ) +
                                  (hoverValue * 1),
                              letterSpacing: 0.2 + (hoverValue * 0.3),
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Status indicator
                        if (widget.isPrimary && _isHovered)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            height: 3,
                            width: 40 * hoverValue,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Theme.of(context).colorScheme.primary,
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),

                    // Corner accents for primary button
                    if (widget.isPrimary && _isHovered)
                      Positioned(
                        top: -8,
                        left: -8,
                        child: Transform.scale(
                          scale: hoverValue,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.isPrimary && _isHovered)
                      Positioned(
                        bottom: -8,
                        right: -8,
                        child: Transform.scale(
                          scale: hoverValue,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Theme.of(context).colorScheme.secondary,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Custom Painter for Ripple Effect
class RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final Offset center;

  RipplePainter({
    required this.animation,
    required this.color,
    required this.center,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity((1 - animation.value) * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final radius = animation.value * 100;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) => true;
}

// Custom Painter for Particle Burst Effect
class ParticleBurstPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final Offset center;

  ParticleBurstPainter({
    required this.animation,
    required this.color,
    required this.center,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity((1 - animation.value) * 0.6)
      ..style = PaintingStyle.fill;

    const particleCount = 12;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 6.28;
      final distance = animation.value * 60;
      final x = center.dx + distance * Math.cos(angle);
      final y = center.dy + distance * Math.sin(angle);

      final size = 4 * (1 - animation.value);
      canvas.drawCircle(Offset(x, y), size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticleBurstPainter oldDelegate) => true;
}

// Helper class for Math functions
class Math {
  static double cos(double radians) => radians.cos();
  static double sin(double radians) => radians.sin();
}

extension on double {
  double cos() {
    return cosValue();
  }

  double sin() {
    return sinValue();
  }

  double cosValue() {
    // Taylor series approximation for cosine
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= -this * this / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double sinValue() {
    // Taylor series approximation for sine
    double result = this;
    double term = this;
    for (int i = 1; i <= 10; i++) {
      term *= -this * this / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}