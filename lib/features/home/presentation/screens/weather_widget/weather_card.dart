import 'package:flutter/material.dart';

import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/glass_card.dart';
import 'weather_details_dialog.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  Map<String, dynamic> _getMockWeatherData() {
    return {
      'temperature': 28,
      'condition': 'Sunny',
      'humidity': 65,
      'windSpeed': 12,
      'feelsLike': 30,
      'uvIndex': 7,
      'pressure': 1013,
      'visibility': 10,
      'sunrise': '06:30 AM',
      'sunset': '06:45 PM',
      'location': 'Rawalpindi',
    };
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'cloudy':
      case 'overcast':
        return Icons.cloud_rounded;
      case 'rainy':
      case 'rain':
        return Icons.water_drop_rounded;
      case 'stormy':
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return const Color(0xFFFF9800);
      case 'cloudy':
      case 'overcast':
        return const Color(0xFF9E9E9E);
      case 'rainy':
      case 'rain':
        return const Color(0xFF2196F3);
      case 'stormy':
      case 'thunderstorm':
        return const Color(0xFF673AB7);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = _getMockWeatherData();
    final weatherColor = _getWeatherColor(weather['condition']);

    return GlassCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => WeatherDetailsDialog(
                weatherData: weather,
                weatherColor: weatherColor,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Weather Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            weatherColor.withOpacity(0.3),
                            weatherColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Icon(
                        _getWeatherIcon(weather['condition']),
                        size: 32,
                        color: weatherColor,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Temperature & Condition
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${weather['temperature']}°',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                  AppMeasurements.getResponsiveFontSize(
                                    context,
                                    baseSize: 36,
                                  ),
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'C',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                  fontSize:
                                  AppMeasurements.getResponsiveFontSize(
                                    context,
                                    baseSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weather['condition'],
                            style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              fontSize:
                              AppMeasurements.getResponsiveFontSize(
                                context,
                                baseSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Location
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.7),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          weather['location'],
                          style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontSize:
                            AppMeasurements.getResponsiveFontSize(
                              context,
                              baseSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Weather Metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric(
                      context,
                      Icons.water_drop_outlined,
                      'Humidity',
                      '${weather['humidity']}%',
                    ),
                    _buildDivider(context),
                    _buildMetric(
                      context,
                      Icons.air_rounded,
                      'Wind',
                      '${weather['windSpeed']} km/h',
                    ),
                    _buildDivider(context),
                    _buildMetric(
                      context,
                      Icons.wb_sunny_outlined,
                      'UV Index',
                      '${weather['uvIndex']}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: AppMeasurements.getResponsiveFontSize(
              context,
              baseSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: AppMeasurements.getResponsiveFontSize(
              context,
              baseSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
    );
  }
}