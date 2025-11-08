import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/glass_card.dart';

class WeatherDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  final Color weatherColor;

  const WeatherDetailsDialog({
    super.key,
    required this.weatherData,
    required this.weatherColor,
  });

  @override
  Widget build(BuildContext context) {
    // --------------------------------------------------------------
    // Responsive values – everything comes from AppMeasurements
    // --------------------------------------------------------------
    final double pad = AppMeasurements.getResponsivePadding(context);
    final double smallPad = AppMeasurements.getResponsiveSmallPadding(context);
    final double extraSmallPad =
    AppMeasurements.getResponsiveExtraSmallPadding(context);
    final double radius = AppMeasurements.getResponsiveBorderRadius(context);
    final double iconLarge = AppMeasurements.getResponsiveIconSizeLarge(context);
    final double iconMedium = AppMeasurements.getResponsiveIconSizeMedium(context);
    final double iconSmall = AppMeasurements.getResponsiveIconSizeSmall(context);

    final double dialogMaxWidth = AppMeasurements.getResponsiveWidth(
      context,
      baseWidth: 400,
    ).clamp(300.0, 500.0); // keep a sensible max for tablets

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(pad), // responsive outer padding
      child: GlassCard(
        child: Container(
          constraints: BoxConstraints(maxWidth: dialogMaxWidth),
          padding: EdgeInsets.all(pad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -------------------- Header --------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weather Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: AppMeasurements.getResponsiveFontSize(
                        context,
                        baseSize: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    iconSize: iconMedium,
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.5),
                      padding: EdgeInsets.all(smallPad),
                    ),
                  ),
                ],
              ),

              SizedBox(height: smallPad),

              // -------------------- Main Weather Card --------------------
              Container(
                padding: EdgeInsets.all(pad * 0.8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      weatherColor.withOpacity(0.2),
                      weatherColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(radius * 2),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getWeatherIcon(weatherData['condition']),
                      size: iconLarge,
                      color: weatherColor,
                    ),
                    SizedBox(height: extraSmallPad),
                    Text(
                      '${weatherData['temperature']}°C',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: AppMeasurements.getResponsiveFontSize(
                          context,
                          baseSize: 36,
                        ),
                      ),
                    ),
                    SizedBox(height: extraSmallPad / 2),
                    Text(
                      weatherData['condition'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                        fontSize: AppMeasurements.getResponsiveFontSize(
                          context,
                          baseSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: extraSmallPad),
                    Text(
                      'Feels like ${weatherData['feelsLike']}°C',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        fontSize: AppMeasurements.getResponsiveFontSize(
                          context,
                          baseSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: smallPad),

              // -------------------- Detail Tiles Grid --------------------
              LayoutBuilder(
                builder: (_, constraints) {
                  // Dynamically decide columns: 2 on phones, 3 on tablets
                  final int crossCount =
                  constraints.maxWidth > 500 ? 3 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossCount,
                    mainAxisSpacing: smallPad,
                    crossAxisSpacing: smallPad,
                    childAspectRatio: 1.8,
                    children: [
                      _buildDetailTile(
                        context,
                        Icons.water_drop_outlined,
                        'Humidity',
                        '${weatherData['humidity']}%',
                        iconSize: iconSmall,
                      ),
                      _buildDetailTile(
                        context,
                        Icons.air_rounded,
                        'Wind Speed',
                        '${weatherData['windSpeed']} km/h',
                        iconSize: iconSmall,
                      ),
                      _buildDetailTile(
                        context,
                        Icons.wb_sunny_outlined,
                        'UV Index',
                        '${weatherData['uvIndex']}',
                        iconSize: iconSmall,
                      ),
                      _buildDetailTile(
                        context,
                        Icons.speed_rounded,
                        'Pressure',
                        '${weatherData['pressure']} hPa',
                        iconSize: iconSmall,
                      ),
                      _buildDetailTile(
                        context,
                        Icons.visibility_rounded,
                        'Visibility',
                        '${weatherData['visibility']} km',
                        iconSize: iconSmall,
                      ),
                      _buildDetailTile(
                        context,
                        Icons.location_on_rounded,
                        'Location',
                        weatherData['location'],
                        iconSize: iconSmall,
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: pad * 0.8),

              // -------------------- Sunrise / Sunset --------------------
              Row(
                children: [
                  Expanded(
                    child: _buildSunTime(
                      context,
                      Icons.wb_sunny_rounded,
                      'Sunrise',
                      weatherData['sunrise'],
                      Colors.orange,
                      iconSize: iconMedium,
                    ),
                  ),
                  SizedBox(width: smallPad),
                  Expanded(
                    child: _buildSunTime(
                      context,
                      Icons.nightlight_round,
                      'Sunset',
                      weatherData['sunset'],
                      Colors.deepPurple,
                      iconSize: iconMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // Helper widgets – now fully responsive
  // --------------------------------------------------------------
  Widget _buildDetailTile(
      BuildContext context,
      IconData icon,
      String label,
      String value, {
        required double iconSize,
      }) {
    final double radius = AppMeasurements.getResponsiveBorderRadius(context);
    final double pad = AppMeasurements.getResponsiveSmallPadding(context);

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(radius * 1.5),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: iconSize,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          SizedBox(width: pad * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 11,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 13,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunTime(
      BuildContext context,
      IconData icon,
      String label,
      String time,
      Color color, {
        required double iconSize,
      }) {
    final double radius = AppMeasurements.getResponsiveBorderRadius(context);
    final double pad = AppMeasurements.getResponsiveSmallPadding(context);

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(radius * 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(width: pad * 0.5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 12,
                  ),
                ),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
}