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
        _drawSimpleRain(canvas, size);
        break;
      case WeatherType.snowy:
      case WeatherType.nightSnow:
        _drawSimpleSnow(canvas, size);
        break;
      case WeatherType.stormy:
      case WeatherType.nightStorm:
        _drawSimpleRain(canvas, size);
        break;
      case WeatherType.nightClear:
        _drawSimpleStars(canvas, size);
        break;
      default:
        break;
    }
  }

  void _drawSimpleRain(Canvas canvas, Size size) {
    _paint
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Only 5 drops
    for (int i = 0; i < 5; i++) {
      final x = (size.width / 5) * i;
      final y = (size.height * ((animationValue * 0.6) % 1.0));
      canvas.drawLine(Offset(x, y), Offset(x - 1, y + 8), _paint);
    }
  }

  void _drawSimpleSnow(Canvas canvas, Size size) {
    _paint
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Only 4 snowflakes
    for (int i = 0; i < 4; i++) {
      final x = (size.width / 4) * i + math.sin(animationValue * math.pi + i) * 6;
      final y = (size.height * ((animationValue * 0.25) % 1.0));
      canvas.drawCircle(Offset(x, y), 1.2, _paint);
    }
  }

  void _drawSimpleStars(Canvas canvas, Size size) {
    _paint.style = PaintingStyle.fill;

    // Only 6 stars
    for (int i = 0; i < 6; i++) {
      final x = (size.width * (i / 6));
      final y = (size.height * ((i * 2) % 6 / 6));
      final twinkle = (math.sin(animationValue * math.pi * 2 + i) + 1) / 2;
      _paint.color = Colors.white.withOpacity(0.2 + twinkle * 0.3);
      canvas.drawCircle(Offset(x, y), 0.8, _paint);
    }
  }

  @override
  bool shouldRepaint(WeatherCardPainter old) => false; // Never repaint
}