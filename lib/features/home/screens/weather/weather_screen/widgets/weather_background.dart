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
        // Base gradient background (static - no repaint)
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _getGradientColors(weatherType, isDark),
                stops: _getGradientStops(weatherType),
              ),
            ),
          ),
        ),

        // Animated weather effects with RepaintBoundary
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: shimmerController,
              builder: (context, child) {
                // Only rebuild when animation value changes significantly
                final roundedValue = (shimmerController.value * 20).round() / 20;
                return CustomPaint(
                  painter: _WeatherEffectsPainter(
                    weatherType: weatherType,
                    animationValue: roundedValue,
                    isDark: isDark,
                  ),
                  isComplex: true,
                  willChange: true,
                );
              },
            ),
          ),
        ),

        // Additional atmospheric layer with RepaintBoundary
        if (_needsAtmosphericLayer(weatherType))
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: shimmerController,
                builder: (context, child) {
                  final roundedValue = (shimmerController.value * 15).round() / 15;
                  return CustomPaint(
                    painter: _AtmosphericLayerPainter(
                      weatherType: weatherType,
                      animationValue: roundedValue,
                    ),
                    isComplex: true,
                    willChange: false,
                  );
                },
              ),
            ),
          ),

        // Text readability overlay (static)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getOverlayColors(weatherType),
                  stops: const [0.0, 0.15, 0.75, 1.0],
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
      if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) {
        return WeatherType.nightRain;
      } else if (c.contains('storm') || c.contains('thunder')) {
        return WeatherType.nightStorm;
      } else if (c.contains('snow') || c.contains('sleet')) {
        return WeatherType.nightSnow;
      } else if (c.contains('cloud') || c.contains('overcast')) {
        return WeatherType.nightCloudy;
      } else if (c.contains('fog') || c.contains('mist')) {
        return WeatherType.nightFog;
      } else {
        return WeatherType.nightClear;
      }
    } else {
      if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) {
        return WeatherType.rainy;
      } else if (c.contains('storm') || c.contains('thunder')) {
        return WeatherType.stormy;
      } else if (c.contains('snow') || c.contains('sleet')) {
        return WeatherType.snowy;
      } else if (c.contains('overcast')) {
        return WeatherType.overcast;
      } else if (c.contains('cloud')) {
        return WeatherType.cloudy;
      } else if (c.contains('fog') || c.contains('mist')) {
        return WeatherType.foggy;
      } else if (c.contains('sunny') || c.contains('clear')) {
        return WeatherType.sunny;
      } else {
        return WeatherType.sunny;
      }
    }
  }

  List<Color> _getGradientColors(WeatherType type, bool isDark) {
    switch (type) {
      case WeatherType.sunny:
        return [
          const Color(0xFF1E88E5),
          const Color(0xFF42A5F5),
          const Color(0xFF64B5F6),
          const Color(0xFFFFA726),
        ];
      case WeatherType.cloudy:
        return [
          const Color(0xFF5C6BC0),
          const Color(0xFF7986CB),
          const Color(0xFF9FA8DA),
          const Color(0xFFB0BEC5),
        ];
      case WeatherType.overcast:
        return [
          const Color(0xFF546E7A),
          const Color(0xFF607D8B),
          const Color(0xFF78909C),
          const Color(0xFF90A4AE),
        ];
      case WeatherType.rainy:
        return [
          const Color(0xFF455A64),
          const Color(0xFF546E7A),
          const Color(0xFF607D8B),
          const Color(0xFF78909C),
        ];
      case WeatherType.snowy:
        return [
          const Color(0xFF64B5F6),
          const Color(0xFF90CAF9),
          const Color(0xFFBBDEFB),
          const Color(0xFFE3F2FD),
        ];
      case WeatherType.stormy:
        return [
          const Color(0xFF263238),
          const Color(0xFF37474F),
          const Color(0xFF455A64),
          const Color(0xFF546E7A),
        ];
      case WeatherType.foggy:
        return [
          const Color(0xFF78909C),
          const Color(0xFF90A4AE),
          const Color(0xFFB0BEC5),
          const Color(0xFFCFD8DC),
        ];
      case WeatherType.nightClear:
        return [
          const Color(0xFF0A192F),
          const Color(0xFF1B2838),
          const Color(0xFF2C3E50),
          const Color(0xFF34495E),
        ];
      case WeatherType.nightRain:
        return [
          const Color(0xFF1A237E),
          const Color(0xFF283593),
          const Color(0xFF3949AB),
          const Color(0xFF5C6BC0),
        ];
      case WeatherType.nightStorm:
        return [
          const Color(0xFF000000),
          const Color(0xFF212121),
          const Color(0xFF424242),
          const Color(0xFF616161),
        ];
      case WeatherType.nightSnow:
        return [
          const Color(0xFF1A237E),
          const Color(0xFF283593),
          const Color(0xFF3949AB),
          const Color(0xFF5C6BC0),
        ];
      case WeatherType.nightCloudy:
        return [
          const Color(0xFF263238),
          const Color(0xFF37474F),
          const Color(0xFF455A64),
          const Color(0xFF546E7A),
        ];
      case WeatherType.nightFog:
        return [
          const Color(0xFF37474F),
          const Color(0xFF455A64),
          const Color(0xFF546E7A),
          const Color(0xFF607D8B),
        ];
    }
  }

  List<double> _getGradientStops(WeatherType type) {
    switch (type) {
      case WeatherType.sunny:
        return [0.0, 0.4, 0.7, 1.0];
      case WeatherType.cloudy:
      case WeatherType.overcast:
        return [0.0, 0.35, 0.65, 1.0];
      case WeatherType.rainy:
      case WeatherType.stormy:
        return [0.0, 0.3, 0.6, 1.0];
      default:
        return [0.0, 0.33, 0.66, 1.0];
    }
  }

  List<Color> _getOverlayColors(WeatherType type) {
    switch (type) {
      case WeatherType.sunny:
        return [
          Colors.black.withOpacity(0.25),
          Colors.black.withOpacity(0.08),
          Colors.transparent,
          Colors.black.withOpacity(0.15),
        ];
      case WeatherType.cloudy:
      case WeatherType.overcast:
        return [
          Colors.black.withOpacity(0.35),
          Colors.black.withOpacity(0.15),
          Colors.black.withOpacity(0.05),
          Colors.black.withOpacity(0.25),
        ];
      case WeatherType.rainy:
      case WeatherType.stormy:
        return [
          Colors.black.withOpacity(0.4),
          Colors.black.withOpacity(0.2),
          Colors.black.withOpacity(0.1),
          Colors.black.withOpacity(0.3),
        ];
      case WeatherType.foggy:
        return [
          Colors.black.withOpacity(0.3),
          Colors.black.withOpacity(0.12),
          Colors.transparent,
          Colors.black.withOpacity(0.2),
        ];
      default:
        return [
          Colors.black.withOpacity(0.35),
          Colors.black.withOpacity(0.15),
          Colors.transparent,
          Colors.black.withOpacity(0.25),
        ];
    }
  }

  bool _needsAtmosphericLayer(WeatherType type) {
    return type == WeatherType.cloudy ||
        type == WeatherType.overcast ||
        type == WeatherType.foggy ||
        type == WeatherType.nightCloudy;
  }
}

// =============================================================================
// OPTIMIZED WEATHER EFFECTS PAINTER
// =============================================================================
class _WeatherEffectsPainter extends CustomPainter {
  final WeatherType weatherType;
  final double animationValue;
  final bool isDark;

  // Cached paint objects
  static final Map<String, Paint> _paintCache = {};

  _WeatherEffectsPainter({
    required this.weatherType,
    required this.animationValue,
    required this.isDark,
  });

  Paint _getPaint(String key, Color color, {PaintingStyle? style, double? strokeWidth}) {
    final cacheKey = '$key-${color.value}-${style?.index}-$strokeWidth';
    return _paintCache.putIfAbsent(
      cacheKey,
          () => Paint()
        ..color = color
        ..style = style ?? PaintingStyle.fill
        ..strokeWidth = strokeWidth ?? 1.0,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (weatherType) {
      case WeatherType.sunny:
        _drawSunEffect(canvas, size);
        break;
      case WeatherType.rainy:
        _drawRainEffect(canvas, size, intensity: 0.6);
        break;
      case WeatherType.snowy:
        _drawSnowEffect(canvas, size);
        break;
      case WeatherType.stormy:
        _drawRainEffect(canvas, size, intensity: 1.0);
        _drawLightningFlash(canvas, size);
        break;
      case WeatherType.cloudy:
        _drawCloudsEffect(canvas, size, density: 0.7);
        break;
      case WeatherType.overcast:
        _drawCloudsEffect(canvas, size, density: 1.0);
        _drawDarkCloudsLayer(canvas, size);
        break;
      case WeatherType.foggy:
        _drawFogEffect(canvas, size);
        break;
      case WeatherType.nightClear:
        _drawStarsEffect(canvas, size);
        _drawMoonEffect(canvas, size);
        break;
      case WeatherType.nightRain:
        _drawRainEffect(canvas, size, intensity: 0.6);
        _drawStarsEffect(canvas, size);
        break;
      case WeatherType.nightStorm:
        _drawRainEffect(canvas, size, intensity: 1.0);
        _drawLightningFlash(canvas, size);
        break;
      case WeatherType.nightSnow:
        _drawSnowEffect(canvas, size);
        _drawStarsEffect(canvas, size);
        break;
      case WeatherType.nightCloudy:
        _drawCloudsEffect(canvas, size, density: 0.8);
        _drawStarsEffect(canvas, size);
        break;
      case WeatherType.nightFog:
        _drawFogEffect(canvas, size);
        break;
    }
  }

  void _drawSunEffect(Canvas canvas, Size size) {
    final rayPaint = _getPaint('sunRay', Colors.white.withOpacity(0.06));
    final center = Offset(size.width * 0.85, size.height * 0.15);

    // Reduced from 12 to 8 rays
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + animationValue * math.pi * 0.5;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + math.cos(angle) * 40, center.dy + math.sin(angle) * 40)
        ..lineTo(
          center.dx + math.cos(angle + 0.15) * 90,
          center.dy + math.sin(angle + 0.15) * 90,
        )
        ..lineTo(
          center.dx + math.cos(angle - 0.15) * 90,
          center.dy + math.sin(angle - 0.15) * 90,
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }

    // Reduced from 15 to 8 particles
    final particlePaint = _getPaint('particle', Colors.white.withOpacity(0.1));
    for (int i = 0; i < 8; i++) {
      final x = (size.width * (i / 8)) + (animationValue * 30);
      final y = size.height * 0.35 + math.sin(animationValue * math.pi * 2 + i) * 20;
      canvas.drawCircle(Offset(x % size.width, y), 2.5, particlePaint);
    }
  }

  void _drawRainEffect(Canvas canvas, Size size, {required double intensity}) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.35 * intensity)
      ..strokeWidth = intensity > 0.8 ? 2.5 : 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Reduced from 50 to 30 drops
    final dropCount = (30 * intensity).toInt();
    for (int i = 0; i < dropCount; i++) {
      final x = (size.width / dropCount) * i;
      final speed = 0.65 + (i % 3) * 0.2 * intensity;
      final y = (size.height * ((animationValue * speed) % 1.0)) - 18;
      final length = 14.0 + (i % 4) * 4 * intensity;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - (intensity * 2), y + length),
        paint,
      );
    }

    // Reduced splashes from 20 to 10
    if (intensity > 0.7) {
      final splashPaint = Paint()..style = PaintingStyle.fill;

      for (int i = 0; i < 10; i++) {
        final x = (size.width / 10) * i;
        final progress = (animationValue * 3.5 + i * 0.15) % 1.0;
        final y = size.height - 18;
        final radius = progress * 7;

        canvas.drawCircle(
          Offset(x, y),
          radius,
          splashPaint..color = Colors.white.withOpacity((1.0 - progress) * 0.12),
        );
      }
    }
  }

  void _drawSnowEffect(Canvas canvas, Size size) {
    final paint = _getPaint('snow', Colors.white.withOpacity(0.75));

    // Reduced from 40 to 25 snowflakes
    for (int i = 0; i < 25; i++) {
      final speed = 0.22 + (i % 4) * 0.07;
      final x = (size.width / 25) * i + math.sin(animationValue * math.pi * 2 + i) * 18;
      final y = (size.height * ((animationValue * speed) % 1.0));
      final radius = 1.9 + (i % 3) * 0.7;

      canvas.drawCircle(Offset(x, y), radius, paint);

      // Reduced from 6 to 4 arms
      final armPaint = Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      for (int j = 0; j < 4; j++) {
        final angle = (j / 4) * 2 * math.pi;
        canvas.drawLine(
          Offset(x, y),
          Offset(x + math.cos(angle) * radius * 1.4, y + math.sin(angle) * radius * 1.4),
          armPaint,
        );
      }
    }
  }

  void _drawCloudsEffect(Canvas canvas, Size size, {required double density}) {
    final paint = _getPaint('cloud', Colors.white.withOpacity(0.08 * density));

    // Reduced from 4 to 3 clouds
    final cloudCount = (3 * density).toInt();
    for (int i = 0; i < cloudCount; i++) {
      final x = (size.width * (i / cloudCount) + animationValue * 55) %
          (size.width + 140) - 70;
      final y = size.height * (0.18 + i * 0.14);
      final cloudSize = 60.0 + i * 12;

      // Reduced circles per cloud
      canvas.drawCircle(Offset(x, y), cloudSize * 0.52, paint);
      canvas.drawCircle(Offset(x - cloudSize * 0.32, y), cloudSize * 0.38, paint);
      canvas.drawCircle(Offset(x + cloudSize * 0.32, y), cloudSize * 0.38, paint);
    }
  }

  void _drawDarkCloudsLayer(Canvas canvas, Size size) {
    final paint = _getPaint('darkCloud', Colors.black.withOpacity(0.12));

    for (int i = 0; i < 2; i++) {
      final x = (size.width * (i / 2) + animationValue * 35) % (size.width + 100) - 50;
      final y = size.height * (0.25 + i * 0.12);
      final cloudSize = 70.0 + i * 10;

      canvas.drawCircle(Offset(x, y), cloudSize * 0.48, paint);
    }
  }

  void _drawFogEffect(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

    // Reduced from 4 to 3
    for (int i = 0; i < 3; i++) {
      final offset = (animationValue * 45 + i * 28) % size.width;
      canvas.drawOval(
        Rect.fromLTWH(offset - 55, size.height * (0.32 + i * 0.18), 150, 65),
        paint,
      );
    }
  }

  void _drawStarsEffect(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Reduced from 60 to 40 stars
    for (int i = 0; i < 40; i++) {
      final x = (size.width * (i / 40));
      final y = (size.height * ((i * 7) % 40 / 40));
      final twinkle = (math.sin(animationValue * math.pi * 2 + i) + 1) / 2;
      final radius = 0.95 + (i % 3) * 0.45;

      paint.color = Colors.white.withOpacity(0.28 + twinkle * 0.52);
      canvas.drawCircle(Offset(x, y), radius * twinkle, paint);
    }
  }

  void _drawMoonEffect(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.16);

    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    canvas.drawCircle(center, 38, glowPaint);

    final moonPaint = _getPaint('moon', Colors.white.withOpacity(0.28));
    canvas.drawCircle(center, 26, moonPaint);
  }

  void _drawLightningFlash(Canvas canvas, Size size) {
    if (animationValue > 0.85 && animationValue < 0.88) {
      final paint = _getPaint('lightning', Colors.white.withOpacity(0.15));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_WeatherEffectsPainter oldDelegate) {
    // Only repaint if weather type changes or animation value changed significantly
    return oldDelegate.weatherType != weatherType ||
        (oldDelegate.animationValue - animationValue).abs() > 0.05;
  }
}

// =============================================================================
// OPTIMIZED ATMOSPHERIC LAYER PAINTER
// =============================================================================
class _AtmosphericLayerPainter extends CustomPainter {
  final WeatherType weatherType;
  final double animationValue;

  _AtmosphericLayerPainter({
    required this.weatherType,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);

    switch (weatherType) {
      case WeatherType.cloudy:
        paint.color = Colors.white.withOpacity(0.05);
        break;
      case WeatherType.overcast:
        paint.color = Colors.black.withOpacity(0.08);
        break;
      case WeatherType.foggy:
        paint.color = Colors.white.withOpacity(0.12);
        break;
      case WeatherType.nightCloudy:
        paint.color = Colors.black.withOpacity(0.15);
        break;
      default:
        return;
    }

    final path = Path();
    path.moveTo(0, size.height * 0.4);

    // Reduced sampling from 10 to 20 pixels
    for (double x = 0; x <= size.width; x += 20) {
      final y = size.height * 0.4 +
          math.sin((x / size.width + animationValue) * 2 * math.pi) * 40;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AtmosphericLayerPainter oldDelegate) {
    return oldDelegate.weatherType != weatherType ||
        (oldDelegate.animationValue - animationValue).abs() > 0.067;
  }
}