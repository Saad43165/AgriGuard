import '../models/weather_types.dart';

class WeatherAnimationUrls {
  static const _base =
      'https://raw.githubusercontent.com/mrdarrengriffin/google-weather-icons/main/sets/lottie';

  static String forWeatherType(WeatherType type) {
    final isNight = type.name.startsWith('night');
    final variant = isNight ? 'phone_portrait_night' : 'phone_portrait';

    // These filenames exist in the repo (via GitHub contents API).
    // Night folder doesn’t contain rain/snow, so we intentionally fall back
    // to the day variant for those conditions to keep UX consistent.
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
        return '$_base/phone_portrait/heavy_rain_phone.json';
      case WeatherType.snowy:
      case WeatherType.nightSnow:
        return '$_base/phone_portrait/heavy_snow_phone.json';
      case WeatherType.stormy:
      case WeatherType.nightStorm:
        // Use a strong thunderstorm background.
        return isNight
            ? '$_base/$variant/strongthunderstorm_dm_phoneportrait.json'
            : '$_base/$variant/strongthunderstorm_lm_phoneportrait.json';
    }
  }
}

