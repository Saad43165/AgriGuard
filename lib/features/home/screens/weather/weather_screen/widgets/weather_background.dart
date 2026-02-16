import 'package:flutter/material.dart';

class WeatherBackground extends StatelessWidget {
  final Color weatherColor;
  final AnimationController shimmerController;

  const WeatherBackground({
    super.key,
    required this.weatherColor,
    required this.shimmerController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                weatherColor,
                weatherColor.withOpacity(0.85),
                weatherColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated wave overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: CustomPaint(
                    painter: _GradientWavePainter(
                      animationValue: shimmerController.value,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Soft glow circles
              const _GlowCircle(
                top: -100,
                right: -50,
                size: 300,
                opacity: 0.15,
              ),
              const _GlowCircle(
                bottom: -80,
                left: -60,
                size: 250,
                opacity: 0.10,
              ),
              const _GlowCircle(
                top: 200,
                left: -100,
                size: 200,
                opacity: 0.08,
              ),
              // Animated particles
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticlesPainter(
                    animationValue: shimmerController.value,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double? top, bottom, left, right;
  final double size;
  final double opacity;

  const _GlowCircle({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(opacity),
              Colors.white.withOpacity(opacity * 0.5),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _GradientWavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.2),
          color.withOpacity(0.0),
        ],
        stops: [
          (animationValue - 0.3).clamp(0.0, 1.0),
          animationValue.clamp(0.0, 1.0),
          (animationValue + 0.3).clamp(0.0, 1.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _ParticlesPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _ParticlesPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 15; i++) {
      final x = (size.width / 15) * i;
      final y = (size.height * ((animationValue + i * 0.1) % 1.0));
      final radius = 2.0 + (i % 3);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}