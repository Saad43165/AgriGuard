import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/weather_types.dart';

class WeatherCardPainter extends CustomPainter {
  final WeatherType weatherType;
  final double animationValue;
  final bool isDark;

  // Cached paint objects
  static final Map<String, Paint> _paintCache = {};

  WeatherCardPainter({
    required this.weatherType,
    required this.animationValue,
    required this.isDark,
  });

  Paint _getPaint(String key, Color color, {PaintingStyle? style, double? strokeWidth, StrokeCap? strokeCap}) {
    final cacheKey = '$key-${color.value}-${style?.index}-$strokeWidth-${strokeCap?.index}';
    return _paintCache.putIfAbsent(
      cacheKey,
          () => Paint()
        ..color = color
        ..style = style ?? PaintingStyle.fill
        ..strokeWidth = strokeWidth ?? 1.0
        ..strokeCap = strokeCap ?? StrokeCap.butt,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (weatherType) {
      case WeatherType.sunny:
        _drawSunnyEffect(canvas, size);
        break;
      case WeatherType.rainy:
        _drawRainEffect(canvas, size, intensity: 0.5);
        break;
      case WeatherType.snowy:
        _drawSnowEffect(canvas, size);
        break;
      case WeatherType.stormy:
        _drawRainEffect(canvas, size, intensity: 0.8);
        break;
      case WeatherType.cloudy:
        _drawCloudsEffect(canvas, size, density: 0.6);
        break;
      case WeatherType.overcast:
        _drawCloudsEffect(canvas, size, density: 0.9);
        break;
      case WeatherType.foggy:
        _drawFogEffect(canvas, size);
        break;
      case WeatherType.nightClear:
        _drawStarsEffect(canvas, size);
        _drawMoonEffect(canvas, size);
        break;
      case WeatherType.nightRain:
        _drawRainEffect(canvas, size, intensity: 0.5);
        _drawStarsEffect(canvas, size);
        break;
      case WeatherType.nightStorm:
        _drawRainEffect(canvas, size, intensity: 0.8);
        break;
      case WeatherType.nightSnow:
        _drawSnowEffect(canvas, size);
        _drawStarsEffect(canvas, size);
        break;
      case WeatherType.nightCloudy:
        _drawCloudsEffect(canvas, size, density: 0.7);
        _drawStarsEffect(canvas, size);
        break;
      case WeatherType.nightFog:
        _drawFogEffect(canvas, size);
        break;
    }
  }

  void _drawSunnyEffect(Canvas canvas, Size size) {
    final rayPaint = _getPaint('sunRay', Colors.white.withOpacity(0.06));
    final center = Offset(size.width * 0.85, size.height * 0.2);

    // Reduced from 8 to 6 rays
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * math.pi + animationValue * math.pi * 0.5;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + math.cos(angle) * 20, center.dy + math.sin(angle) * 20)
        ..lineTo(
          center.dx + math.cos(angle + 0.2) * 40,
          center.dy + math.sin(angle + 0.2) * 40,
        )
        ..lineTo(
          center.dx + math.cos(angle - 0.2) * 40,
          center.dy + math.sin(angle - 0.2) * 40,
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }

    // Reduced from 8 to 5 particles
    final particlePaint = _getPaint('particle', Colors.white.withOpacity(0.08));
    for (int i = 0; i < 5; i++) {
      final x = (size.width * (i / 5)) + (animationValue * 20);
      final y = size.height * 0.4 + math.sin(animationValue * math.pi * 2 + i) * 12;
      canvas.drawCircle(Offset(x % size.width, y), 2, particlePaint);
    }
  }

  void _drawRainEffect(Canvas canvas, Size size, {required double intensity}) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3 * intensity)
      ..strokeWidth = 1.5 * intensity
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Reduced from 25 to 15 drops
    final dropCount = (15 * intensity).toInt();
    for (int i = 0; i < dropCount; i++) {
      final x = (size.width / dropCount) * i;
      final speed = 0.6 + (i % 2) * 0.2 * intensity;
      final y = (size.height * ((animationValue * speed) % 1.0)) - 12;
      final length = 10.0 + (i % 3) * 3 * intensity;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - intensity, y + length),
        paint,
      );
    }
  }

  void _drawSnowEffect(Canvas canvas, Size size) {
    final paint = _getPaint('snow', Colors.white.withOpacity(0.6));

    // Reduced from 20 to 12 snowflakes
    for (int i = 0; i < 12; i++) {
      final speed = 0.25 + (i % 3) * 0.08;
      final x = (size.width / 12) * i + math.sin(animationValue * math.pi * 2 + i) * 10;
      final y = (size.height * ((animationValue * speed) % 1.0));
      final radius = 1.5 + (i % 2) * 0.5;

      canvas.drawCircle(Offset(x, y), radius, paint);

      final armPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      // Reduced from 4 to 3 arms
      for (int j = 0; j < 3; j++) {
        final angle = (j / 3) * 2 * math.pi;
        canvas.drawLine(
          Offset(x, y),
          Offset(x + math.cos(angle) * radius, y + math.sin(angle) * radius),
          armPaint,
        );
      }
    }
  }

  void _drawCloudsEffect(Canvas canvas, Size size, {required double density}) {
    final paint = _getPaint('cloud', Colors.white.withOpacity(0.08 * density));

    // Kept at 2 clouds
    final cloudCount = (2 * density).toInt();
    for (int i = 0; i < cloudCount; i++) {
      final x = (size.width * (i / cloudCount) + animationValue * 40) %
          (size.width + 80) - 40;
      final y = size.height * (0.25 + i * 0.2);
      final cloudSize = 35.0 + i * 8;

      // Reduced cloud detail
      canvas.drawCircle(Offset(x, y), cloudSize * 0.5, paint);
      canvas.drawCircle(Offset(x - cloudSize * 0.3, y), cloudSize * 0.35, paint);
      canvas.drawCircle(Offset(x + cloudSize * 0.3, y), cloudSize * 0.35, paint);
    }
  }

  void _drawFogEffect(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    for (int i = 0; i < 2; i++) {
      final offset = (animationValue * 30 + i * 20) % size.width;
      canvas.drawOval(
        Rect.fromLTWH(offset - 30, size.height * (0.4 + i * 0.2), 90, 40),
        paint,
      );
    }
  }

  void _drawStarsEffect(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Reduced from 30 to 20 stars
    for (int i = 0; i < 20; i++) {
      final x = (size.width * (i / 20));
      final y = (size.height * ((i * 5) % 20 / 20));
      final twinkle = (math.sin(animationValue * math.pi * 2 + i) + 1) / 2;
      final radius = 0.8 + (i % 2) * 0.3;

      paint.color = Colors.white.withOpacity(0.25 + twinkle * 0.4);
      canvas.drawCircle(Offset(x, y), radius * twinkle, paint);
    }
  }

  void _drawMoonEffect(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.2);

    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(center, 22, glowPaint);

    final moonPaint = _getPaint('moon', Colors.white.withOpacity(0.25));
    canvas.drawCircle(center, 15, moonPaint);
  }

  @override
  bool shouldRepaint(WeatherCardPainter oldDelegate) {
    // Only repaint if weather type changes or animation value changed significantly
    return oldDelegate.weatherType != weatherType ||
        (oldDelegate.animationValue - animationValue).abs() > 0.05;
  }
}