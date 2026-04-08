import '../models/weather_types.dart';

class WeatherIconAnimationUrls {
  static const _base =
      'https://raw.githubusercontent.com/mrdarrengriffin/google-weather-icons/main/sets/lottie';

  /// Small-ish animations suitable for icon-size use in the card.
  /// We prefer the "lm/dm phoneportrait" icon-like files when available.
  static String forWeatherType(WeatherType type) {
    switch (type) {
      case WeatherType.sunny:
        return '$_base/phone_portrait/clear_lm_phoneportrait.json';
      case WeatherType.nightClear:
        return '$_base/phone_portrait_night/clear_dm_phoneportrait.json';
      case WeatherType.cloudy:
      case WeatherType.overcast:
      case WeatherType.foggy:
        return '$_base/phone_portrait/cloudy_lm_phoneportrait.json';
      case WeatherType.nightCloudy:
      case WeatherType.nightFog:
        return '$_base/phone_portrait_night/cloudy_dm_phoneportrait.json';
      case WeatherType.rainy:
      case WeatherType.nightRain:
        // Smaller than heavy_rain background; works well as an "icon".
        return '$_base/phone_portrait/drizzle_phone.json';
      case WeatherType.snowy:
      case WeatherType.nightSnow:
        return '$_base/phone_portrait/scattered_snow_phone.json';
      case WeatherType.stormy:
      case WeatherType.nightStorm:
        // Icon-style versions exist for both day/night.
        return type == WeatherType.nightStorm
            ? '$_base/phone_portrait_night/thunderstorm_dm_phoneportrait.json'
            : '$_base/phone_portrait/thunderstorm_lm_phoneportrait.json';
    }
  }
}

