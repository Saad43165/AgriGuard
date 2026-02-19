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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationHeader(),
              const SizedBox(height: 20),
              _buildTemperatureDisplay(),
              const SizedBox(height: 24),
              _buildQuickStats(),
              const SizedBox(height: 16),
              _buildAdditionalInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x4D000000), // Dark overlay for contrast
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x40FFFFFF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  weatherData.cityName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              weatherData.region.isNotEmpty
                  ? '${weatherData.region}, ${weatherData.country}'
                  : weatherData.country,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xE6FFFFFF),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              '${DateFormat('EEEE, MMMM d').format(DateTime.now())} • ${_getLocalTime()}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xCCFFFFFF),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0x4D000000), // Dark overlay
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x40FFFFFF), width: 1.5),
      ),
      child: Column(
        children: [
          // Weather Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x4DFFFFFF), width: 2),
            ),
            child: Icon(
              _iconForCondition(weatherData.conditionText, weatherData.isDay),
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Temperature
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weatherData.temperature.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 88,
                  fontWeight: FontWeight.w200,
                  height: 0.9,
                  color: Colors.white,
                  letterSpacing: -4,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  '°',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Condition
          Text(
            weatherData.conditionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Feels Like
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.thermostat_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Feels like ${weatherData.feelsLike.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x4D000000), // Dark overlay
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x40FFFFFF), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              Icons.water_drop_rounded,
              'Humidity',
              '${weatherData.humidity}%',
            ),
          ),
          Container(
            width: 1.5,
            height: 50,
            color: const Color(0x33FFFFFF),
          ),
          Expanded(
            child: _statItem(
              Icons.air_rounded,
              'Wind',
              '${weatherData.windSpeed.toStringAsFixed(0)} km/h',
            ),
          ),
          Container(
            width: 1.5,
            height: 50,
            color: const Color(0x33FFFFFF),
          ),
          Expanded(
            child: _statItem(
              Icons.visibility_rounded,
              'Visibility',
              '${weatherData.visibilityKm.toStringAsFixed(0)} km',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xCCFFFFFF),
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            Icons.compress_rounded,
            'Pressure',
            '${weatherData.pressure.toStringAsFixed(0)} mb',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoCard(
            Icons.wb_sunny_rounded,
            'UV Index',
            weatherData.uvIndex.toStringAsFixed(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoCard(
            Icons.cloud_rounded,
            'Clouds',
            '${weatherData.cloudCover}%',
          ),
        ),
      ],
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x4D000000), // Dark overlay
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xCCFFFFFF),
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

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

  IconData _iconForCondition(String condition, int isDay) {
    final c = condition.toLowerCase();
    if (isDay == 0) {
      if (c.contains('clear')) return Icons.nightlight_round;
      if (c.contains('cloudy') || c.contains('overcast')) return Icons.cloud;
    }
    if (c.contains('sunny') || c.contains('clear')) return Icons.wb_sunny_rounded;
    if (c.contains('cloudy') || c.contains('overcast')) return Icons.cloud_rounded;
    if (c.contains('rain') || c.contains('drizzle')) return Icons.grain_rounded;
    if (c.contains('storm') || c.contains('thunder')) return Icons.thunderstorm_rounded;
    if (c.contains('snow') || c.contains('sleet')) return Icons.ac_unit_rounded;
    if (c.contains('fog') || c.contains('mist')) return Icons.foggy;
    return Icons.wb_cloudy_rounded;
  }
}