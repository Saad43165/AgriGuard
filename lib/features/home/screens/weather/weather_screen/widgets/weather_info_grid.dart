import 'package:flutter/material.dart';
import '../../models/weather_model.dart';

class WeatherInfoGrid extends StatelessWidget {
  final WeatherModel weatherData;

  const WeatherInfoGrid({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weather Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 20),
              _buildRow(
                InfoItem(
                  icon: Icons.water_drop_rounded,
                  label: 'Humidity',
                  value: '${weatherData.humidity}%',
                  color: Colors.blue,
                ),
                InfoItem(
                  icon: Icons.air_rounded,
                  label: 'Wind Speed',
                  value: '${weatherData.windSpeed.toStringAsFixed(1)} km/h',
                  color: Colors.cyan,
                ),
              ),
              _buildDivider(),
              _buildRow(
                InfoItem(
                  icon: Icons.wb_sunny_rounded,
                  label: 'UV Index',
                  value: weatherData.uvIndex.toStringAsFixed(1),
                  color: Colors.orange,
                ),
                InfoItem(
                  icon: Icons.speed_rounded,
                  label: 'Pressure',
                  value: '${weatherData.pressure.toStringAsFixed(0)} mb',
                  color: Colors.purple,
                ),
              ),
              _buildDivider(),
              _buildRow(
                InfoItem(
                  icon: Icons.visibility_rounded,
                  label: 'Visibility',
                  value: '${weatherData.visibilityKm.toStringAsFixed(1)} km',
                  color: Colors.teal,
                ),
                InfoItem(
                  icon: Icons.cloud_rounded,
                  label: 'Cloud Cover',
                  value: '${weatherData.cloudCover}%',
                  color: Colors.blueGrey,
                ),
              ),
              _buildDivider(),
              _buildRow(
                InfoItem(
                  icon: Icons.water_rounded,
                  label: 'Precipitation',
                  value: '${weatherData.precipitation.toStringAsFixed(1)} mm',
                  color: Colors.lightBlue,
                ),
                InfoItem(
                  icon: Icons.air,
                  label: 'Wind Gust',
                  value: '${weatherData.gustSpeed.toStringAsFixed(1)} km/h',
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(InfoItem left, InfoItem right) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Expanded(child: left),
        Container(
          width: 2,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Expanded(child: right),
      ],
    ),
  );

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Divider(
      color: Colors.white.withOpacity(0.2),
      height: 1,
      thickness: 1,
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.2),
        Colors.white.withOpacity(0.15),
      ],
    ),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: Colors.white.withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const InfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}