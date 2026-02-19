import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/weather_model.dart';

class WeatherInfoGrid extends StatelessWidget {
  final WeatherModel weatherData;

  const WeatherInfoGrid({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 20),
            _buildPrimaryMetrics(),
            const SizedBox(height: 16),
            _buildWindCard(),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x4D000000), Color(0x33000000)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x59FFFFFF), width: 2),
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
            child: const Icon(Icons.wb_twilight_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Text(
            'Weather Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildFeatureCard(
            icon: Icons.water_drop_rounded,
            label: 'Humidity',
            value: '${weatherData.humidity}%',
            gradient: const [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFeatureCard(
            icon: Icons.wb_sunny_rounded,
            label: 'UV Index',
            value: weatherData.uvIndex.toStringAsFixed(1),
            gradient: [_getUVColor(weatherData.uvIndex), _getUVColor(weatherData.uvIndex)],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x4D000000), Color(0x33000000)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x59FFFFFF), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xE6FFFFFF),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x4D000000), Color(0x33000000)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x59FFFFFF), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF00A3CC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.air_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Wind Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF00A3CC)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.speed_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${weatherData.windSpeed.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Speed',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xD9FFFFFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'km/h',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xB3FFFFFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Transform.rotate(
                      angle: weatherData.windDegree * math.pi / 180,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      weatherData.windDirection,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Direction',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xD9FFFFFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${weatherData.windDegree.round()}°',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xB3FFFFFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wind_power_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${weatherData.gustSpeed.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gusts',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xD9FFFFFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'km/h',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xB3FFFFFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.visibility_rounded,
                label: 'Visibility',
                value: '${weatherData.visibilityKm.toStringAsFixed(1)} km',
                gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.speed_rounded,
                label: 'Pressure',
                value: '${weatherData.pressure.toStringAsFixed(0)} mb',
                gradient: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.cloud_rounded,
                label: 'Cloud Cover',
                value: '${weatherData.cloudCover}%',
                gradient: const [Color(0xFF757F9A), Color(0xFFD7DDE8)],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.water_rounded,
                label: 'Precipitation',
                value: '${weatherData.precipitation.toStringAsFixed(1)} mm',
                gradient: const [Color(0xFF3A7BD5), Color(0xFF00D2FF)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x4D000000), Color(0x33000000)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x59FFFFFF), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xE6FFFFFF),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getUVColor(double uv) {
    if (uv <= 2) return const Color(0xFF4CAF50);
    if (uv <= 5) return const Color(0xFFFFC107);
    if (uv <= 7) return const Color(0xFFFF9800);
    if (uv <= 10) return const Color(0xFFF44336);
    return const Color(0xFF9C27B0);
  }
}