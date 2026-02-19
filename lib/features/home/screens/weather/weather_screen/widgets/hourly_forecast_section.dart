import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_model.dart';

class HourlyForecastSection extends StatelessWidget {
  final ForecastDay forecastDay;
  final Color weatherColor;

  const HourlyForecastSection({
    super.key,
    required this.forecastDay,
    required this.weatherColor,
  });

  @override
  Widget build(BuildContext context) {
    final hourlyData = _generateHourlyData();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Hourly Forecast',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 150,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: hourlyData.length,
              itemBuilder: (context, index) {
                final hour = hourlyData[index];
                return _buildHourlyCard(hour, index == 0);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHourlyCard(Map<String, dynamic> hour, bool isNow) {
    return Container(
      width: 95,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isNow
              ? [
            Colors.white.withOpacity(0.35),
            Colors.white.withOpacity(0.25),
          ]
              : [
            Colors.black.withOpacity(0.25),
            Colors.black.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(isNow ? 0.5 : 0.35),
          width: isNow ? 2.5 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (isNow)
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            hour['time'],
            style: TextStyle(
              fontSize: isNow ? 14 : 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black38,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          Icon(
            hour['icon'],
            color: Colors.white,
            size: 36,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          Text(
            '${hour['temp']}°',
            style: TextStyle(
              fontSize: isNow ? 22 : 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.water_drop, color: Colors.white, size: 12),
                const SizedBox(width: 3),
                Text(
                  '${hour['rain']}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateHourlyData() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> hours = [];

    for (int i = 0; i < 24; i++) {
      final hour = now.add(Duration(hours: i));
      final temp = (forecastDay.avgTemp + (i % 2 == 0 ? 2 : -2)).toInt();

      hours.add({
        'time': i == 0 ? 'Now' : DateFormat('HH:00').format(hour),
        'temp': temp,
        'icon': _getHourIcon(hour.hour),
        'rain': (forecastDay.dailyChanceOfRain * (1 - i * 0.02)).clamp(0, 100).toInt(),
      });
    }

    return hours;
  }

  IconData _getHourIcon(int hour) {
    if (hour >= 6 && hour < 12) return Icons.wb_sunny_rounded;
    if (hour >= 12 && hour < 18) return Icons.wb_cloudy_rounded;
    if (hour >= 18 && hour < 21) return Icons.cloud_rounded;
    return Icons.nightlight_round;
  }
}