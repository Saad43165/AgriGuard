class WeatherModel {
  final String cityName;
  final String region;
  final String country;
  final double latitude;
  final double longitude;
  final String timezone;
  final String localTime;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final double windDegree;
  final String windDirection;
  final double pressure;
  final double precipitation;
  final int cloudCover;
  final int isDay;
  final int conditionCode;
  final String conditionText;
  final String iconUrl;
  final String lastUpdated;
  final double uvIndex;
  final double visibilityKm;
  final double gustSpeed;

  WeatherModel({
    required this.cityName,
    required this.region,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.localTime,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDegree,
    required this.windDirection,
    required this.pressure,
    required this.precipitation,
    required this.cloudCover,
    required this.isDay,
    required this.conditionCode,
    required this.conditionText,
    required this.iconUrl,
    required this.lastUpdated,
    required this.uvIndex,
    required this.visibilityKm,
    required this.gustSpeed,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final current = json['current'];
    final condition = current['condition'];

    return WeatherModel(
      cityName: location['name'] ?? 'Unknown',
      region: location['region'] ?? '',
      country: location['country'] ?? '',
      latitude: (location['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (location['lon'] as num?)?.toDouble() ?? 0.0,
      timezone: location['tz_id'] ?? '',
      localTime: location['localtime'] ?? '',
      temperature: (current['temp_c'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (current['feelslike_c'] as num?)?.toDouble() ?? 0.0,
      humidity: current['humidity'] as int? ?? 0,
      windSpeed: (current['wind_kph'] as num?)?.toDouble() ?? 0.0,
      windDegree: (current['wind_degree'] as num?)?.toDouble() ?? 0.0,
      windDirection: current['wind_dir'] ?? 'N',
      pressure: (current['pressure_mb'] as num?)?.toDouble() ?? 0.0,
      precipitation: (current['precip_mm'] as num?)?.toDouble() ?? 0.0,
      cloudCover: current['cloud'] as int? ?? 0,
      isDay: current['is_day'] as int? ?? 1,
      conditionCode: condition['code'] as int? ?? 1000,
      conditionText: condition['text'] ?? 'Unknown',
      iconUrl: 'https:${condition['icon']}',
      lastUpdated: current['last_updated'] ?? 'Unknown',
      uvIndex: (current['uv'] as num?)?.toDouble() ?? 0.0,
      visibilityKm: (current['vis_km'] as num?)?.toDouble() ?? 0.0,
      gustSpeed: (current['gust_kph'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ForecastDay {
  final String date;
  final String dateEpoch;
  final double maxTemp;
  final double minTemp;
  final double avgTemp;
  final double maxWind;
  final double totalPrecip;
  final double totalSnow;
  final double avgVisibility;
  final int avgHumidity;
  final int dailyWillItRain;
  final int dailyChanceOfRain;
  final int dailyWillItSnow;
  final int dailyChanceOfSnow;
  final String conditionText;
  final String iconUrl;
  final int conditionCode;
  final double uvIndex;
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String moonPhase;
  final int moonIllumination;

  ForecastDay({
    required this.date,
    required this.dateEpoch,
    required this.maxTemp,
    required this.minTemp,
    required this.avgTemp,
    required this.maxWind,
    required this.totalPrecip,
    required this.totalSnow,
    required this.avgVisibility,
    required this.avgHumidity,
    required this.dailyWillItRain,
    required this.dailyChanceOfRain,
    required this.dailyWillItSnow,
    required this.dailyChanceOfSnow,
    required this.conditionText,
    required this.iconUrl,
    required this.conditionCode,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
    required this.moonIllumination,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    final day = json['day'];
    final condition = day['condition'];
    final astro = json['astro'];

    return ForecastDay(
      date: json['date'] ?? '',
      dateEpoch: json['date_epoch']?.toString() ?? '',
      maxTemp: (day['maxtemp_c'] as num?)?.toDouble() ?? 0.0,
      minTemp: (day['mintemp_c'] as num?)?.toDouble() ?? 0.0,
      avgTemp: (day['avgtemp_c'] as num?)?.toDouble() ?? 0.0,
      maxWind: (day['maxwind_kph'] as num?)?.toDouble() ?? 0.0,
      totalPrecip: (day['totalprecip_mm'] as num?)?.toDouble() ?? 0.0,
      totalSnow: (day['totalsnow_cm'] as num?)?.toDouble() ?? 0.0,
      avgVisibility: (day['avgvis_km'] as num?)?.toDouble() ?? 0.0,
      avgHumidity: day['avghumidity'] as int? ?? 0,
      dailyWillItRain: day['daily_will_it_rain'] as int? ?? 0,
      dailyChanceOfRain: day['daily_chance_of_rain'] as int? ?? 0,
      dailyWillItSnow: day['daily_will_it_snow'] as int? ?? 0,
      dailyChanceOfSnow: day['daily_chance_of_snow'] as int? ?? 0,
      conditionText: condition['text'] ?? 'Unknown',
      iconUrl: 'https:${condition['icon']}',
      conditionCode: condition['code'] as int? ?? 1000,
      uvIndex: (day['uv'] as num?)?.toDouble() ?? 0.0,
      sunrise: astro['sunrise'] ?? '',
      sunset: astro['sunset'] ?? '',
      moonrise: astro['moonrise'] ?? '',
      moonset: astro['moonset'] ?? '',
      moonPhase: astro['moon_phase'] ?? '',
      moonIllumination: int.tryParse(astro['moon_illumination']?.toString() ?? '0') ?? 0,
    );
  }
}

class WeatherForecast {
  final WeatherModel current;
  final List<ForecastDay> forecast;

  WeatherForecast({
    required this.current,
    required this.forecast,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final current = WeatherModel.fromJson(json);
    final forecastDays = (json['forecast']?['forecastday'] as List?)
        ?.map((day) => ForecastDay.fromJson(day))
        .toList() ?? [];

    return WeatherForecast(
      current: current,
      forecast: forecastDays,
    );
  }
}