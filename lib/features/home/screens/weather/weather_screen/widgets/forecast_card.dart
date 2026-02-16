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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(isDark),
          child: Row(
            children: [
              // Day info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRainChip(),
                  ],
                ),
              ),

              // Weather icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _iconFor(day.conditionText),
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 20),

              // Temperatures
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${day.maxTemp.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.white.withOpacity(0.7), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${day.minTemp.toStringAsFixed(0)}°',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Arrow indicator
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRainChip() {
    if (day.dailyChanceOfRain <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            '${day.dailyChanceOfRain}%',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(isDark ? 0.15 : 0.25),
        Colors.white.withOpacity(isDark ? 0.1 : 0.2),
      ],
    ),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: Colors.white.withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  IconData _iconFor(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('sunny') || c.contains('clear')) return Icons.wb_sunny_rounded;
    if (c.contains('cloudy') || c.contains('overcast')) return Icons.cloud_rounded;
    if (c.contains('rain') || c.contains('drizzle')) return Icons.water_drop_rounded;
    if (c.contains('storm') || c.contains('thunder')) return Icons.thunderstorm_rounded;
    if (c.contains('snow') || c.contains('sleet')) return Icons.ac_unit_rounded;
    if (c.contains('fog') || c.contains('mist')) return Icons.foggy;
    return Icons.wb_cloudy_rounded;
  }
}