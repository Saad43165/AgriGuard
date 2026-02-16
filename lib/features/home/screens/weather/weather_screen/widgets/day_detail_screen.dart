import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_model.dart';

class DayDetailScreen extends StatelessWidget {
  final ForecastDay forecastDay;
  final Color weatherColor;

  const DayDetailScreen({
    super.key,
    required this.forecastDay,
    required this.weatherColor,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(forecastDay.date);
    final dayName = DateFormat('EEEE, MMMM d').format(date);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              weatherColor,
              weatherColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  dayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Main weather card
                    _buildMainWeatherCard(),
                    const SizedBox(height: 24),

                    // Sun & Moon
                    _buildAstroCard(),
                    const SizedBox(height: 24),

                    // Detailed info grid
                    _buildDetailedInfoGrid(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _glassDecoration(),
      child: Column(
        children: [
          Icon(
            _getWeatherIcon(forecastDay.conditionText),
            size: 100,
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          Text(
            forecastDay.conditionText,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTempColumn('High', forecastDay.maxTemp, Icons.arrow_upward),
              Container(
                width: 2,
                height: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildTempColumn('Low', forecastDay.minTemp, Icons.arrow_downward),
              Container(
                width: 2,
                height: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildTempColumn('Avg', forecastDay.avgTemp, Icons.thermostat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempColumn(String label, double temp, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          '${temp.toStringAsFixed(0)}°',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAstroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sun & Moon',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAstroItem(
                  Icons.wb_sunny_rounded,
                  'Sunrise',
                  forecastDay.sunrise,
                ),
              ),
              Expanded(
                child: _buildAstroItem(
                  Icons.wb_twilight,
                  'Sunset',
                  forecastDay.sunset,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAstroItem(
                  Icons.nightlight_round,
                  'Moonrise',
                  forecastDay.moonrise,
                ),
              ),
              Expanded(
                child: _buildAstroItem(
                  Icons.brightness_3,
                  'Moonset',
                  forecastDay.moonset,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  forecastDay.moonPhase,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${forecastDay.moonIllumination}% Illuminated',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAstroItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfoGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.air_rounded, 'Max Wind', '${forecastDay.maxWind.toStringAsFixed(1)} km/h'),
          _buildDivider(),
          _buildInfoRow(Icons.water_drop, 'Precipitation', '${forecastDay.totalPrecip.toStringAsFixed(1)} mm'),
          _buildDivider(),
          _buildInfoRow(Icons.ac_unit, 'Snow', '${forecastDay.totalSnow.toStringAsFixed(1)} cm'),
          _buildDivider(),
          _buildInfoRow(Icons.visibility, 'Avg Visibility', '${forecastDay.avgVisibility.toStringAsFixed(1)} km'),
          _buildDivider(),
          _buildInfoRow(Icons.water_drop_outlined, 'Avg Humidity', '${forecastDay.avgHumidity}%'),
          _buildDivider(),
          _buildInfoRow(Icons.wb_sunny_rounded, 'UV Index', forecastDay.uvIndex.toStringAsFixed(1)),
          _buildDivider(),
          _buildInfoRow(Icons.umbrella, 'Chance of Rain', '${forecastDay.dailyChanceOfRain}%'),
          _buildDivider(),
          _buildInfoRow(Icons.ac_unit_rounded, 'Chance of Snow', '${forecastDay.dailyChanceOfSnow}%'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.2),
      height: 1,
    );
  }

  BoxDecoration _glassDecoration() => BoxDecoration(
    color: Colors.white.withOpacity(0.2),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white.withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  IconData _getWeatherIcon(String condition) {
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