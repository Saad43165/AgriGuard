import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_model.dart';

class ForecastCard extends StatelessWidget {
  final ForecastDay day;
  final int index;
  final VoidCallback onTap;

  const ForecastCard({
    super.key,
    required this.day,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(day.date);
    final dayName = index == 0 ? 'Today' : DateFormat('EEEE').format(date);
    final dateStr = DateFormat('MMM d').format(date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: const Color(0x1AFFFFFF),
        highlightColor: const Color(0x0DFFFFFF),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0x4D000000), // Dark overlay for contrast
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x40FFFFFF), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Weather Icon - Left
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getIconGradient(),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      _iconFor(day.conditionText),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Day Info - Middle (Expanded)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xE6FFFFFF),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (day.dailyChanceOfRain > 0) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x33FFFFFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.water_drop_rounded,
                                    color: Color(0xFF64B5F6),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${day.dailyChanceOfRain}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        day.conditionText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xCCFFFFFF),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Temperatures - Right
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_upward,
                          color: Color(0xFFFF8A80),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${day.maxTemp.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_downward,
                          color: Color(0xFF80D8FF),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${day.minTemp.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xE6FFFFFF),
                            letterSpacing: -0.3,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Chevron Arrow
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getIconGradient() {
    final c = day.conditionText.toLowerCase();

    if (c.contains('sunny') || c.contains('clear')) {
      return [const Color(0xFFFFB74D), const Color(0xFFFF9800)];
    }

    if (c.contains('rain') || c.contains('drizzle')) {
      return [const Color(0xFF64B5F6), const Color(0xFF42A5F5)];
    }

    if (c.contains('storm') || c.contains('thunder')) {
      return [const Color(0xFF9575CD), const Color(0xFF7E57C2)];
    }

    if (c.contains('snow') || c.contains('sleet')) {
      return [const Color(0xFF81D4FA), const Color(0xFF4FC3F7)];
    }

    if (c.contains('cloudy') || c.contains('overcast')) {
      return [const Color(0xFFB0BEC5), const Color(0xFF90A4AE)];
    }

    if (c.contains('fog') || c.contains('mist')) {
      return [const Color(0xFFCFD8DC), const Color(0xFFB0BEC5)];
    }

    return [const Color(0xFF80CBC4), const Color(0xFF4DB6AC)];
  }

  IconData _iconFor(String condition) {
    final c = condition.toLowerCase();

    if (c.contains('sunny') || c.contains('clear')) {
      return Icons.wb_sunny_rounded;
    }
    if (c.contains('partly cloudy')) {
      return Icons.wb_cloudy_rounded;
    }
    if (c.contains('cloudy') || c.contains('overcast')) {
      return Icons.cloud_rounded;
    }
    if (c.contains('rain') || c.contains('drizzle')) {
      return Icons.grain_rounded;
    }
    if (c.contains('storm') || c.contains('thunder')) {
      return Icons.thunderstorm_rounded;
    }
    if (c.contains('snow') || c.contains('sleet')) {
      return Icons.ac_unit_rounded;
    }
    if (c.contains('fog') || c.contains('mist')) {
      return Icons.foggy;
    }

    return Icons.wb_cloudy_rounded;
  }
}