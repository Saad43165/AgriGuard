import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_model.dart';

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
              _locationRow(),
              const SizedBox(height: 12),
              _dateAndTimeChips(),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    _weatherIcon(),
                    const SizedBox(height: 24),
                    _temperature(),
                    const SizedBox(height: 12),
                    _conditionText(),
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

  Widget _locationRow() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.25),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weatherData.cityName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${weatherData.region}, ${weatherData.country}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _dateAndTimeChips() => Wrap(
    spacing: 10,
    children: [
      _chip(
        icon: Icons.calendar_today_rounded,
        text: DateFormat('EEEE, MMM d').format(DateTime.now()),
      ),
      _chip(
        icon: Icons.access_time_rounded,
        text: _getLocalTime(),
      ),
    ],
  );

  Widget _chip({required IconData icon, required String text}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.25),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _getLocalTime() {
    if (weatherData.localTime.isNotEmpty && weatherData.localTime != 'Unknown') {
      try {
        final localDateTime = DateTime.parse(weatherData.localTime);
        return DateFormat('HH:mm').format(localDateTime);
      } catch (e) {
        return DateFormat('HH:mm').format(DateTime.now());
      }
    }
    return DateFormat('HH:mm').format(DateTime.now());
  }

  Widget _weatherIcon() => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.15),
        ],
      ),
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withOpacity(0.4),
        width: 3,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withOpacity(0.2),
          blurRadius: 30,
          spreadRadius: 5,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Icon(
      _iconForCondition(weatherData.conditionText, weatherData.isDay),
      size: 100,
      color: Colors.white,
      shadows: const [
        Shadow(
          color: Colors.black26,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
  );

  Widget _temperature() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.2),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 2,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          weatherData.temperature.toStringAsFixed(0),
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w300,
            height: 1,
            color: Colors.white,
            letterSpacing: -4,
            shadows: [
              Shadow(
                color: Colors.black45,
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            '°C',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _conditionText() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.25),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 1.5,
      ),
    ),
    child: Text(
      weatherData.conditionText,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    ),
  );

  Widget _feelsLikeChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.15),
        ],
      ),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(
        color: Colors.white.withOpacity(0.4),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.thermostat_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(
          'Feels like ${weatherData.feelsLike.toStringAsFixed(0)}°C',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
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