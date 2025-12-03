import 'package:flutter/material.dart';
import '../../../../../../../core/constants/app_measurements.dart';

class WeatherMetricsRow extends StatelessWidget {
  final int humidity;
  final double windSpeed;
  final double uvIndex;
  final Color weatherColor;

  const WeatherMetricsRow({
    super.key,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.weatherColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetric(
          context,
          Icons.water_drop_rounded,
          'Humidity',
          '$humidity%',
          Colors.blue,
        ),
        _buildDivider(context),
        _buildMetric(
          context,
          Icons.air_rounded,
          'Wind',
          windSpeed.toStringAsFixed(1),
          Colors.cyan,
        ),
        _buildDivider(context),
        _buildMetric(
          context,
          Icons.wb_sunny_rounded,
          'UV',
          uvIndex.toStringAsFixed(1),
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetric(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      Color color,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}