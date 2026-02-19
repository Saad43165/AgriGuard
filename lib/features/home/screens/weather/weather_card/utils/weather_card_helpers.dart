// lib/features/home/screens/weather/weather_card/utils/weather_card_helpers.dart
import 'package:flutter/material.dart';

import '../../models/weather_types.dart';

class WeatherCardHelpers {
  static WeatherType getWeatherType(String condition, int isDay) {
    final c = condition.toLowerCase().trim();

    if (isDay == 0) {
      if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) {
        return WeatherType.nightRain;
      } else if (c.contains('storm') || c.contains('thunder')) {
        return WeatherType.nightStorm;
      } else if (c.contains('snow') || c.contains('sleet')) {
        return WeatherType.nightSnow;
      } else if (c.contains('cloud') || c.contains('overcast')) {
        return WeatherType.nightCloudy;
      } else if (c.contains('fog') || c.contains('mist')) {
        return WeatherType.nightFog;
      } else {
        return WeatherType.nightClear;
      }
    } else {
      if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) {
        return WeatherType.rainy;
      } else if (c.contains('storm') || c.contains('thunder')) {
        return WeatherType.stormy;
      } else if (c.contains('snow') || c.contains('sleet')) {
        return WeatherType.snowy;
      } else if (c.contains('overcast')) {
        return WeatherType.overcast;
      } else if (c.contains('cloud')) {
        return WeatherType.cloudy;
      } else if (c.contains('fog') || c.contains('mist')) {
        return WeatherType.foggy;
      } else if (c.contains('sunny') || c.contains('clear')) {
        return WeatherType.sunny;
      } else {
        return WeatherType.sunny;
      }
    }
  }

  // ... rest of your helper methods (unchanged)

  static IconData getWeatherIcon(String condition, int isDay) {
    final lowerCondition = condition.toLowerCase();
    if (isDay == 0) {
      if (lowerCondition.contains('clear')) return Icons.nightlight_round;
      if (lowerCondition.contains('cloudy') || lowerCondition.contains('overcast')) {
        return Icons.cloud;
      }
    }
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
    }
    return Icons.wb_cloudy_rounded;
  }

  static Color getWeatherColor(String condition, int isDay, bool isDark) {
    final c = condition.toLowerCase();

    if (isDay == 0) {
      if (c.contains('rain') || c.contains('drizzle')) {
        return const Color(0xFF1A237E);
      } else if (c.contains('storm') || c.contains('thunder')) {
        return const Color(0xFF000000);
      } else if (c.contains('snow') || c.contains('sleet')) {
        return const Color(0xFF1A237E);
      } else if (c.contains('cloud') || c.contains('overcast')) {
        return const Color(0xFF263238);
      } else if (c.contains('fog') || c.contains('mist')) {
        return const Color(0xFF37474F);
      } else {
        return const Color(0xFF0A192F);
      }
    } else {
      if (c.contains('sunny') || c.contains('clear')) {
        return const Color(0xFF1E88E5);
      } else if (c.contains('rain') || c.contains('drizzle')) {
        return const Color(0xFF455A64);
      } else if (c.contains('storm') || c.contains('thunder')) {
        return const Color(0xFF263238);
      } else if (c.contains('snow') || c.contains('sleet')) {
        return const Color(0xFF64B5F6);
      } else if (c.contains('overcast')) {
        return const Color(0xFF546E7A);
      } else if (c.contains('cloud')) {
        return const Color(0xFF5C6BC0);
      } else if (c.contains('fog') || c.contains('mist')) {
        return const Color(0xFF78909C);
      }
      return const Color(0xFF1E88E5);
    }
  }

  static List<Color> getGradientColors(String condition, int isDay, bool isDark) {
    final c = condition.toLowerCase();

    if (isDay == 0) {
      if (c.contains('rain') || c.contains('drizzle')) {
        return [const Color(0xFF1A237E), const Color(0xFF283593), const Color(0xFF3949AB)];
      } else if (c.contains('storm') || c.contains('thunder')) {
        return [const Color(0xFF000000), const Color(0xFF212121), const Color(0xFF424242)];
      } else if (c.contains('snow') || c.contains('sleet')) {
        return [const Color(0xFF283593), const Color(0xFF3949AB), const Color(0xFF5C6BC0)];
      } else if (c.contains('cloud') || c.contains('overcast')) {
        return [const Color(0xFF37474F), const Color(0xFF455A64), const Color(0xFF546E7A)];
      } else if (c.contains('fog') || c.contains('mist')) {
        return [const Color(0xFF455A64), const Color(0xFF546E7A), const Color(0xFF607D8B)];
      } else {
        return [const Color(0xFF0D1B2A), const Color(0xFF1B2838), const Color(0xFF2C3E50)];
      }
    } else {
      if (c.contains('sunny') || c.contains('clear')) {
        return [const Color(0xFF1E88E5), const Color(0xFF42A5F5), const Color(0xFF64B5F6)];
      } else if (c.contains('rain') || c.contains('drizzle')) {
        return [const Color(0xFF546E7A), const Color(0xFF607D8B), const Color(0xFF78909C)];
      } else if (c.contains('storm') || c.contains('thunder')) {
        return [const Color(0xFF37474F), const Color(0xFF455A64), const Color(0xFF546E7A)];
      } else if (c.contains('snow') || c.contains('sleet')) {
        return [const Color(0xFF90CAF9), const Color(0xFFBBDEFB), const Color(0xFFE3F2FD)];
      } else if (c.contains('overcast')) {
        return [const Color(0xFF546E7A), const Color(0xFF607D8B), const Color(0xFF78909C)];
      } else if (c.contains('cloud')) {
        return [const Color(0xFF5C6BC0), const Color(0xFF7986CB), const Color(0xFF9FA8DA)];
      } else if (c.contains('fog') || c.contains('mist')) {
        return [const Color(0xFF90A4AE), const Color(0xFFB0BEC5), const Color(0xFFCFD8DC)];
      }
      return [const Color(0xFF1E88E5), const Color(0xFF42A5F5), const Color(0xFF64B5F6)];
    }
  }

  static String getLocationTime(dynamic provider) {
    final weatherData = provider.currentWeather;

    if (weatherData?.localTime != null && weatherData!.localTime.isNotEmpty) {
      try {
        final localDateTime = DateTime.parse(weatherData.localTime);
        final hour = localDateTime.hour.toString().padLeft(2, '0');
        final minute = localDateTime.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      } catch (e) {
        return _getCurrentTime();
      }
    }
    return _getCurrentTime();
  }

  static String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}