// lib/widgets/current_weather_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_model.dart';
import '../items/icon_item.dart';

class CurrentWeatherSection extends StatelessWidget {
  final WeatherModel weatherData;
  final Animation<double> fadeAnimation;

  const CurrentWeatherSection({
    super.key,
    required this.weatherData,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location
              _locationRow(),
              const SizedBox(height: 12),
              _dateChip(),
              const SizedBox(height: 40),

              // Main temperature + icon
              Center(
                child: Column(
                  children: [
                    _weatherIcon(),
                    const SizedBox(height: 24),
                    _temperature(),
                    const SizedBox(height: 12),
                    Text(
                      weatherData.conditionText,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _feelsLikeChip(),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationRow() => Row(
    children: [
      const IconItem(icon: Icons.location_on_rounded, size: 24),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weatherData.cityName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${weatherData.region}, ${weatherData.country}',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _dateChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
      style: TextStyle(
        fontSize: 14,
        color: Colors.white.withOpacity(0.95),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  );

  Widget _weatherIcon() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.white.withOpacity(0.3),
          blurRadius: 30,
          spreadRadius: 5,
        ),
      ],
    ),
    child: Icon(
      _iconForCondition(weatherData.conditionText, weatherData.isDay),
      size: 100,
      color: Colors.white,
    ),
  );

  Widget _temperature() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        weatherData.temperature.toStringAsFixed(0),
        style: const TextStyle(
          fontSize: 96,
          fontWeight: FontWeight.w200,
          height: 1,
          color: Colors.white,
          letterSpacing: -4,
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text(
          '°C',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
      ),
    ],
  );

  Widget _feelsLikeChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      'Feels like ${weatherData.feelsLike.toStringAsFixed(0)}°C',
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withOpacity(0.95),
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  IconData _iconForCondition(String condition, int isDay) {
    final c = condition.toLowerCase();
    if (isDay == 0) {
      if (c.contains('clear')) return Icons.nightlight_round;
      if (c.contains('cloudy') || c.contains('overcast')) return Icons.cloud;
    }
    if (c.contains('sunny') || c.contains('clear')) return Icons.wb_sunny_rounded;
    if (c.contains('cloudy') || c.contains('overcast')) return Icons.cloud_rounded;
    if (c.contains('rain') || c.contains('drizzle')) return Icons.water_drop_rounded;
    if (c.contains('storm') || c.contains('thunder')) return Icons.thunderstorm_rounded;
    if (c.contains('snow') || c.contains('sleet')) return Icons.ac_unit_rounded;
    if (c.contains('fog') || c.contains('mist')) return Icons.foggy;
    return Icons.wb_cloudy_rounded;
  }
}