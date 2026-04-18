// lib/features/home/screens/weather/weather_card/weather_card.dart
// Clean minimal weather card — botanical app style
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/weather_provider.dart';
import '../../../../../core/widgets/app_themes.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !provider.hasData) {
          return _buildSkeleton(context);
        }
        if (provider.hasData) {
          return _buildCard(context, provider);
        }
        return _buildError(context, provider);
      },
    );
  }

  Widget _buildCard(BuildContext context, WeatherProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weather = provider.currentWeather!;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    final icon = _weatherIcon(weather.conditionText, weather.isDay == 1);
    final temp = '${weather.temperature.toStringAsFixed(0)}°C';
    final condition = weather.conditionText;
    final location = weather.cityName;
    final humidity = '${weather.humidity}%';
    final wind = '${weather.windSpeed.toStringAsFixed(0)} km/h';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          // Weather icon
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          // Main info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(temp, style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(condition, style: TextStyle(
                      fontSize: 13, color: captionColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(location, style: TextStyle(
                      fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          ),
          // Right side metrics
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _metric(Icons.water_drop_outlined, humidity, captionColor),
              const SizedBox(height: 4),
              _metric(Icons.air_rounded, wind, captionColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 68,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: const Center(
        child: SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
      ),
    );
  }

  Widget _buildError(BuildContext context, WeatherProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          const Text('🌤️', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Text('Weather unavailable',
            style: TextStyle(fontSize: 13,
              color: isDark ? AppColors.darkCaption : AppColors.lightCaption))),
          TextButton(
            onPressed: () => provider.refreshWeather(),
            child: const Text('Retry', style: TextStyle(
              color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _weatherIcon(String condition, bool isDay) {
    final c = condition.toLowerCase();
    if (c.contains('sunny') || c.contains('clear')) return isDay ? '☀️' : '🌙';
    if (c.contains('partly') || c.contains('cloudy')) return isDay ? '⛅' : '🌤️';
    if (c.contains('overcast')) return '☁️';
    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    if (c.contains('thunder') || c.contains('storm')) return '⛈️';
    if (c.contains('snow') || c.contains('sleet')) return '❄️';
    if (c.contains('fog') || c.contains('mist')) return '🌫️';
    if (c.contains('wind')) return '💨';
    return isDay ? '🌤️' : '🌙';
  }
}
