import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/weather_types.dart';

class WeatherBackground extends StatelessWidget {
  final Color weatherColor;
  final AnimationController shimmerController;
  final String condition;
  final int isDay;

  const WeatherBackground({
    super.key,
    required this.weatherColor,
    required this.shimmerController,
    required this.condition,
    required this.isDay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weatherType = _getWeatherType(condition, isDay);

    return Stack(
      children: [
        // Static gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _getGradientColors(weatherType, isDark),
              ),
            ),
          ),
        ),

        // Animated effects
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: shimmerController,
              builder: (context, _) {
                return CustomPaint(
                  painter: WeatherPainter(
                    weatherType: weatherType,
                    animationValue: shimmerController.value,
                  ),
                  isComplex: true,
                  willChange: true,
                );
              },
            ),
          ),
        ),

        // Overlay gradient
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  WeatherType _getWeatherType(String condition, int isDay) {
    final c = condition.toLowerCase().trim();

    if (isDay == 0) {
      if (c.contains('rain') || c.contains('drizzle')) return WeatherType.nightRain;
      if (c.contains('storm') || c.contains('thunder')) return WeatherType.nightStorm;
      if (c.contains('snow')) return WeatherType.nightSnow;
      if (c.contains('cloud')) return WeatherType.nightCloudy;
      return WeatherType.nightClear;
    } else {
      if (c.contains('rain') || c.contains('drizzle')) return WeatherType.rainy;
      if (c.contains('storm') || c.contains('thunder')) return WeatherType.stormy;
      if (c.contains('snow')) return WeatherType.snowy;
      if (c.contains('cloud')) return WeatherType.cloudy;
      return WeatherType.sunny;
    }
  }

  List<Color> _getGradientColors(WeatherType type, bool isDark) {
    switch (type) {
      case WeatherType.sunny:
        return [const Color(0xFF1E88E5), const Color(0xFF64B5F6)];
      case WeatherType.cloudy:
        return [const Color(0xFF5C6BC0), const Color(0xFF9FA8DA)];
      case WeatherType.rainy:
        return [const Color(0xFF455A64), const Color(0xFF78909C)];
      case WeatherType.snowy:
        return [const Color(0xFF64B5F6), const Color(0xFFE3F2FD)];
      case WeatherType.stormy:
        return [const Color(0xFF263238), const Color(0xFF546E7A)];
      case WeatherType.nightClear:
        return [const Color(0xFF0A192F), const Color(0xFF34495E)];
      case WeatherType.nightRain:
        return [const Color(0xFF1A237E), const Color(0xFF5C6BC0)];
      case WeatherType.nightStorm:
        return [const Color(0xFF000000), const Color(0xFF424242)];
      case WeatherType.nightSnow:
        return [const Color(0xFF1A237E), const Color(0xFF5C6BC0)];
      case WeatherType.nightCloudy:
        return [const Color(0xFF263238), const Color(0xFF546E7A)];
      default:
        return [const Color(0xFF1E88E5), const Color(0xFF64B5F6)];
    }
  }
}

class WeatherPainter extends CustomPainter {
  final WeatherType weatherType;
  final double animationValue;
  final Paint _paint = Paint();

  WeatherPainter({
    required this.weatherType,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (weatherType) {
      case WeatherType.sunny:
        _drawSunRays(canvas, size);
        break;
      case WeatherType.cloudy:
      case WeatherType.nightCloudy:
        _drawClouds(canvas, size);
        break;
      case WeatherType.rainy:
      case WeatherType.nightRain:
        _drawRain(canvas, size);
        break;
      case WeatherType.stormy:
      case WeatherType.nightStorm:
        _drawStorm(canvas, size);
        break;
      case WeatherType.snowy:
      case WeatherType.nightSnow:
        _drawSnow(canvas, size);
        break;
      case WeatherType.nightClear:
        _drawStars(canvas, size);
        break;
      default:
        break;
    }
  }

  void _drawSunRays(Canvas canvas, Size size) {
    _paint
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width * 0.8, size.height * 0.15);
    final rotation = animationValue * 2 * math.pi;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + rotation;
      final startRadius = 40.0;
      final endRadius = 120.0;

      final path = Path()
        ..moveTo(
          center.dx + math.cos(angle - 0.1) * startRadius,
          center.dy + math.sin(angle - 0.1) * startRadius,
        )
        ..lineTo(
          center.dx + math.cos(angle) * endRadius,
          center.dy + math.sin(angle) * endRadius,
        )
        ..lineTo(
          center.dx + math.cos(angle + 0.1) * startRadius,
          center.dy + math.sin(angle + 0.1) * startRadius,
        )
        ..close();

      canvas.drawPath(path, _paint);
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    _paint
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // 3 clouds moving slowly
    for (int i = 0; i < 3; i++) {
      final offsetX = (animationValue * size.width + i * size.width / 3) % (size.width + 200) - 100;
      final y = size.height * 0.2 + i * 80.0;

      _drawCloud(canvas, Offset(offsetX, y));
    }
  }

  void _drawCloud(Canvas canvas, Offset position) {
    // Simple cloud made of circles
    canvas.drawCircle(position, 25, _paint);
    canvas.drawCircle(position.translate(30, 0), 30, _paint);
    canvas.drawCircle(position.translate(60, 0), 25, _paint);
    canvas.drawCircle(position.translate(30, -15), 28, _paint);
  }

  void _drawRain(Canvas canvas, Size size) {
    _paint
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 30 raindrops
    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final x = size.width * (i / 30.0) + math.sin(animationValue * math.pi + i) * 10;
      final y = (size.height * ((animationValue * 1.5 + i * 0.1) % 1.0));

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3, y + 15),
        _paint,
      );
    }
  }

  void _drawStorm(Canvas canvas, Size size) {
    // Draw heavy rain
    _paint
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 40; i++) {
      final x = size.width * (i / 40.0) + math.sin(animationValue * math.pi + i) * 15;
      final y = (size.height * ((animationValue * 2 + i * 0.08) % 1.0));

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 5, y + 20),
        _paint,
      );
    }

    // Lightning flash
    if (animationValue > 0.85 && animationValue < 0.88) {
      _paint
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);

      // Lightning bolt
      _paint
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final lightningPath = Path()
        ..moveTo(size.width * 0.6, 0)
        ..lineTo(size.width * 0.55, size.height * 0.3)
        ..lineTo(size.width * 0.58, size.height * 0.3)
        ..lineTo(size.width * 0.52, size.height * 0.6);

      canvas.drawPath(lightningPath, _paint);
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    _paint
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // 40 snowflakes with gentle drift
    for (int i = 0; i < 40; i++) {
      final baseX = size.width * (i / 40.0);
      final drift = math.sin(animationValue * math.pi * 2 + i) * 20;
      final x = baseX + drift;
      final y = (size.height * ((animationValue * 0.5 + i * 0.025) % 1.0));

      // Draw snowflake
      canvas.drawCircle(Offset(x, y), 2.5, _paint);

      // Add cross pattern for snowflake detail
      _paint
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x - 3, y), Offset(x + 3, y), _paint);
      canvas.drawLine(Offset(x, y - 3), Offset(x, y + 3), _paint);

      _paint.style = PaintingStyle.fill;
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    _paint.style = PaintingStyle.fill;

    // 50 stars with twinkling
    final random = math.Random(123);
    for (int i = 0; i < 50; i++) {
      final x = size.width * (i * 7 % 100 / 100);
      final y = size.height * (i * 13 % 100 / 100);

      // Twinkling effect
      final twinkle = (math.sin(animationValue * math.pi * 2 + i * 0.5) + 1) / 2;
      final opacity = 0.3 + twinkle * 0.5;
      final starSize = 1.0 + twinkle * 1.5;

      _paint.color = Colors.white.withOpacity(opacity);

      // Draw star
      canvas.drawCircle(Offset(x, y), starSize, _paint);

      // Add star points
      if (starSize > 1.8) {
        _paint.strokeWidth = 0.5;
        _paint.style = PaintingStyle.stroke;
        canvas.drawLine(Offset(x - 3, y), Offset(x + 3, y), _paint);
        canvas.drawLine(Offset(x, y - 3), Offset(x, y + 3), _paint);
        _paint.style = PaintingStyle.fill;
      }
    }

    // Shooting star occasionally
    if (animationValue > 0.3 && animationValue < 0.35) {
      _paint
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final progress = (animationValue - 0.3) / 0.05;
      final startX = size.width * 0.7;
      final startY = size.height * 0.2;
      final endX = startX + 100 * progress;
      final endY = startY + 50 * progress;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), _paint);
    }
  }

  @override
  bool shouldRepaint(WeatherPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}