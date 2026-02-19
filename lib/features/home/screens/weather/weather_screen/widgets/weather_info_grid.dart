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
              Row(
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.thermostat_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Weather Details',
                    style: TextStyle(
                      fontSize: 22,
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
              const SizedBox(height: 24),
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
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.4),
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
      color: Colors.white.withOpacity(0.3),
      height: 1,
      thickness: 1.5,
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.black.withOpacity(0.25),
        Colors.black.withOpacity(0.15),
      ],
    ),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: Colors.white.withOpacity(0.35),
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}