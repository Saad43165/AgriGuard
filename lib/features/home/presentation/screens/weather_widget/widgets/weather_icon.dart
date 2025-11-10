import 'package:flutter/material.dart';

class WeatherIcon extends StatelessWidget {
  final String condition;
  final double size;

  const WeatherIcon({
    super.key,
    required this.condition,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      _getWeatherIcon(condition),
      size: size,
      color: _getWeatherColor(condition),
    );
  }

  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) {
      return Icons.wb_sunny_rounded;
    } else if (lowerCondition.contains('cloudy') || lowerCondition.contains('overcast')) {
      return Icons.cloud_rounded;
    } else if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
      return Icons.water_drop_rounded;
    } else if (lowerCondition.contains('storm') || lowerCondition.contains('thunder')) {
      return Icons.thunderstorm_rounded;
    } else if (lowerCondition.contains('snow') || lowerCondition.contains('sleet')) {
      return Icons.ac_unit_rounded;
    } else if (lowerCondition.contains('fog') || lowerCondition.contains('mist')) {
      return Icons.foggy;
    } else {
      return Icons.wb_cloudy_rounded;
    }
  }

  Color _getWeatherColor(String condition) {
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) {
      return const Color(0xFFFF9800);
    } else if (lowerCondition.contains('cloudy') || lowerCondition.contains('overcast')) {
      return const Color(0xFF9E9E9E);
    } else if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
      return const Color(0xFF2196F3);
    } else if (lowerCondition.contains('storm') || lowerCondition.contains('thunder')) {
      return const Color(0xFF673AB7);
    } else if (lowerCondition.contains('snow') || lowerCondition.contains('sleet')) {
      return const Color(0xFF03A9F4);
    } else if (lowerCondition.contains('fog') || lowerCondition.contains('mist')) {
      return const Color(0xFF607D8B);
    } else {
      return const Color(0xFF4CAF50);
    }
  }
}