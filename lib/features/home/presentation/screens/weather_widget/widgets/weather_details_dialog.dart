import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_measurements.dart';
import '../models/weather_model.dart';

class WeatherDetailsDialog extends StatelessWidget {
  final WeatherModel weatherData;
  final Color weatherColor;

  const WeatherDetailsDialog({
    super.key,
    required this.weatherData,
    required this.weatherColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppMeasurements.defaultPadding),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: weatherColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: weatherColor.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    weatherColor.withOpacity(0.2),
                    weatherColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              weatherColor,
                              weatherColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: weatherColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getWeatherIcon(weatherData.conditionText),
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Weather Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: AppMeasurements.getResponsiveFontSize(
                            context,
                            baseSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      iconSize: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
                child: Column(
                  children: [
                    // Main weather display
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            weatherColor.withOpacity(0.15),
                            weatherColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: weatherColor.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Weather icon
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  weatherColor.withOpacity(0.2),
                                  weatherColor.withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: weatherColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _getWeatherIcon(weatherData.conditionText),
                              size: 72,
                              color: weatherColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Temperature
                          Text(
                            '${weatherData.temperature.toStringAsFixed(0)}°',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 64,
                              height: 1,
                              color: weatherColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Condition
                          Text(
                            weatherData.conditionText,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Feels like
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: weatherColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Feels like ${weatherData.feelsLike.toStringAsFixed(0)}°C',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStat(
                            context,
                            Icons.water_drop_rounded,
                            '${weatherData.humidity}%',
                            'Humidity',
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickStat(
                            context,
                            Icons.air_rounded,
                            '${weatherData.windSpeed.toStringAsFixed(1)}',
                            'Wind km/h',
                            Colors.cyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickStat(
                            context,
                            Icons.wb_sunny_rounded,
                            weatherData.uvIndex.toStringAsFixed(1),
                            'UV Index',
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Detailed metrics
                    _buildMetricCard(
                      context,
                      Icons.speed_rounded,
                      'Pressure',
                      '${weatherData.pressure.toStringAsFixed(0)} hPa',
                      Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      context,
                      Icons.visibility_rounded,
                      'Visibility',
                      '${weatherData.visibilityKm.toStringAsFixed(1)} km',
                      Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      context,
                      Icons.location_on_rounded,
                      'Location',
                      '${weatherData.cityName}, ${weatherData.country}',
                      Colors.red,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      context,
                      Icons.cloud_rounded,
                      'Cloud Cover',
                      '${weatherData.cloudCover}%',
                      Colors.blueGrey,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      context,
                      Icons.grain_rounded,
                      'Precipitation',
                      '${weatherData.precipitation} mm',
                      Colors.lightBlue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(
      BuildContext context,
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(0.2),
              ),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) {
      return Icons.wb_sunny_rounded;
    } else if (lowerCondition.contains('cloudy') ||
        lowerCondition.contains('overcast')) {
      return Icons.cloud_rounded;
    } else if (lowerCondition.contains('rain') ||
        lowerCondition.contains('drizzle')) {
      return Icons.water_drop_rounded;
    } else if (lowerCondition.contains('storm') ||
        lowerCondition.contains('thunder')) {
      return Icons.thunderstorm_rounded;
    } else if (lowerCondition.contains('snow') ||
        lowerCondition.contains('sleet')) {
      return Icons.ac_unit_rounded;
    } else if (lowerCondition.contains('fog') ||
        lowerCondition.contains('mist')) {
      return Icons.foggy;
    } else {
      return Icons.wb_cloudy_rounded;
    }
  }
}