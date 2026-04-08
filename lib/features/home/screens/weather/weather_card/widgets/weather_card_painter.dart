import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/weather_types.dart';

class WeatherCardPainter extends CustomPainter {
  final WeatherType weatherType;
  final double animationValue;
  final bool isDark;

  static final Paint _paint = Paint();

  WeatherCardPainter({
    required this.weatherType,
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (weatherType) {
      case WeatherType.rainy:
      case WeatherType.nightRain:
        _drawRain(canvas, size);
        break;
      case WeatherType.snowy:
      case WeatherType.nightSnow:
        _drawSnow(canvas, size);
        break;
      case WeatherType.stormy:
      case WeatherType.nightStorm:
        _drawStorm(canvas, size);
        break;
      case WeatherType.nightClear:
        _drawStars(canvas, size);
        break;
      case WeatherType.cloudy:
      case WeatherType.nightCloudy:
        _drawClouds(canvas, size);
        break;
      default:
        break;
    }
  }

  void _drawRain(Canvas canvas, Size size) {
    _paint
      ..color = Colors.white.withOpacity(isDark ? 0.28 : 0.35)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Drops distributed with oscillation
    for (int i = 0; i < 22; i++) {
      final baseX = size.width * ((i * 37) % 100) / 100;
      final drift = math.sin(animationValue * math.pi * 2 + i) * 8;
      final x = baseX + drift;
      final y = size.height * ((animationValue * 1.6 + i * 0.11) % 1.0);
      canvas.drawLine(Offset(x, y), Offset(x - 3, y + 16), _paint);
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    _paint
      ..color = Colors.white.withOpacity(isDark ? 0.55 : 0.70)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 26; i++) {
      final baseX = size.width * ((i * 17) % 100) / 100;
      final drift = math.sin(animationValue * math.pi * 2 + i) * 14;
      final x = baseX + drift;
      final y = size.height * ((animationValue * 0.55 + i * 0.05) % 1.0);
      final r = 1.3 + ((i % 3) * 0.6);
      canvas.drawCircle(Offset(x, y), r, _paint);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    _paint.style = PaintingStyle.fill;

    for (int i = 0; i < 42; i++) {
      final x = size.width * (((i * 7) % 100) / 100);
      final y = size.height * (((i * 13) % 100) / 100);
      final twinkle = (math.sin(animationValue * math.pi * 2 + i * 0.6) + 1) / 2;
      final opacity = (isDark ? 0.18 : 0.14) + twinkle * (isDark ? 0.35 : 0.28);
      final r = 0.7 + twinkle * 1.3;
      _paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), r, _paint);
    }
  }

  void _drawStorm(Canvas canvas, Size size) {
    _drawRain(canvas, size);

    // occasional lightning flash
    final flash = (math.sin(animationValue * math.pi * 6) + 1) / 2;
    if (flash > 0.92) {
      _paint
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity((flash - 0.92) * 0.8);
      canvas.drawRect(Offset.zero & size, _paint);
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    _paint.style = PaintingStyle.fill;
    final baseOpacity = isDark ? 0.10 : 0.14;
    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.22 + i * 0.16);
      final x = size.width * ((animationValue + i * 0.22) % 1.0);
      _paint.color = Colors.white.withOpacity(baseOpacity + i * 0.03);
      _cloud(canvas, Offset(x, y), 18 + i * 6);
    }
  }

  void _cloud(Canvas canvas, Offset p, double r) {
    canvas.drawCircle(p, r, _paint);
    canvas.drawCircle(p.translate(r * 0.9, 0), r * 1.15, _paint);
    canvas.drawCircle(p.translate(r * 1.8, 0), r, _paint);
    canvas.drawCircle(p.translate(r * 0.9, -r * 0.55), r * 1.05, _paint);
  }

  @override
  bool shouldRepaint(WeatherCardPainter old) =>
      old.weatherType != weatherType ||
      old.animationValue != animationValue ||
      old.isDark != isDark;
}