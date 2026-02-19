import 'dart:ui';

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
    final hourlyData = _getActualHourlyData();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Hourly Forecast',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
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
            child: hourlyData.isEmpty
                ? Center(
              child: Text(
                'No hourly data available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        // The "Blur Behind" effect
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 95,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Darker tint (black opacity) makes white text visible
            color: isNow
                ? const Color(0xFF764BA2).withOpacity(0.6)
                : Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              // Outer layer border
              color: isNow
                  ? Colors.white.withOpacity(0.6)
                  : Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                hour['time'],
                style: TextStyle(
                  fontSize: isNow ? 14 : 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                ),
              ),
              Icon(
                hour['icon'],
                color: Colors.white,
                size: 36,
              ),
              Text(
                '${hour['temp']}°',
                style: TextStyle(
                  fontSize: isNow ? 22 : 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              // Mini rain chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop, color: Colors.white, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      '${hour['rain']}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getActualHourlyData() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final List<Map<String, dynamic>> hourlyDataList = [];

    final hourlyForecasts = forecastDay.hourlyForecasts;

    if (hourlyForecasts.isEmpty) {
      return [];
    }

    int startIndex = 0;
    for (int i = 0; i < hourlyForecasts.length; i++) {
      final hourTime = DateTime.parse(hourlyForecasts[i].time);
      if (hourTime.hour >= currentHour) {
        startIndex = i;
        break;
      }
    }

    final maxHours = (hourlyForecasts.length - startIndex).clamp(0, 24);

    for (int i = 0; i < maxHours; i++) {
      final hourForecast = hourlyForecasts[startIndex + i];
      final hourTime = DateTime.parse(hourForecast.time);

      hourlyDataList.add({
        'time': i == 0 ? 'Now' : DateFormat('HH:00').format(hourTime),
        'temp': hourForecast.tempC.round(),
        'icon': _getWeatherIcon(hourForecast.conditionText, hourForecast.isDay),
        'rain': hourForecast.chanceOfRain,
      });
    }

    return hourlyDataList;
  }

  IconData _getWeatherIcon(String condition, int isDay) {
    final c = condition.toLowerCase();

    if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) {
      return Icons.grain_rounded;
    }

    if (c.contains('thunder') || c.contains('storm')) {
      return Icons.thunderstorm_rounded;
    }

    if (c.contains('snow') || c.contains('sleet') || c.contains('blizzard')) {
      return Icons.ac_unit_rounded;
    }

    if (c.contains('fog') || c.contains('mist') || c.contains('haze')) {
      return Icons.cloud_rounded;
    }

    if (c.contains('overcast') || c.contains('cloudy')) {
      return Icons.wb_cloudy_rounded;
    }

    if (c.contains('partly')) {
      return isDay == 1 ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded;
    }

    if (c.contains('clear') || c.contains('sunny')) {
      return isDay == 1 ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    }

    return isDay == 1 ? Icons.wb_sunny_rounded : Icons.nightlight_round;
  }
}