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

// NEW: HourlyForecast class
class HourlyForecast {
  final String time;
  final int timeEpoch;
  final double tempC;
  final double feelsLikeC;
  final int isDay;
  final String conditionText;
  final String iconUrl;
  final int conditionCode;
  final double windKph;
  final int windDegree;
  final String windDir;
  final double pressureMb;
  final double precipMm;
  final int humidity;
  final int cloud;
  final double visKm;
  final double gustKph;
  final double uvIndex;
  final int chanceOfRain;
  final int chanceOfSnow;
  final int willItRain;
  final int willItSnow;

  HourlyForecast({
    required this.time,
    required this.timeEpoch,
    required this.tempC,
    required this.feelsLikeC,
    required this.isDay,
    required this.conditionText,
    required this.iconUrl,
    required this.conditionCode,
    required this.windKph,
    required this.windDegree,
    required this.windDir,
    required this.pressureMb,
    required this.precipMm,
    required this.humidity,
    required this.cloud,
    required this.visKm,
    required this.gustKph,
    required this.uvIndex,
    required this.chanceOfRain,
    required this.chanceOfSnow,
    required this.willItRain,
    required this.willItSnow,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final condition = json['condition'];

    return HourlyForecast(
      time: json['time'] ?? '',
      timeEpoch: json['time_epoch'] as int? ?? 0,
      tempC: (json['temp_c'] as num?)?.toDouble() ?? 0.0,
      feelsLikeC: (json['feelslike_c'] as num?)?.toDouble() ?? 0.0,
      isDay: json['is_day'] as int? ?? 1,
      conditionText: condition['text'] ?? 'Unknown',
      iconUrl: 'https:${condition['icon']}',
      conditionCode: condition['code'] as int? ?? 1000,
      windKph: (json['wind_kph'] as num?)?.toDouble() ?? 0.0,
      windDegree: json['wind_degree'] as int? ?? 0,
      windDir: json['wind_dir'] ?? 'N',
      pressureMb: (json['pressure_mb'] as num?)?.toDouble() ?? 0.0,
      precipMm: (json['precip_mm'] as num?)?.toDouble() ?? 0.0,
      humidity: json['humidity'] as int? ?? 0,
      cloud: json['cloud'] as int? ?? 0,
      visKm: (json['vis_km'] as num?)?.toDouble() ?? 0.0,
      gustKph: (json['gust_kph'] as num?)?.toDouble() ?? 0.0,
      uvIndex: (json['uv'] as num?)?.toDouble() ?? 0.0,
      chanceOfRain: json['chance_of_rain'] as int? ?? 0,
      chanceOfSnow: json['chance_of_snow'] as int? ?? 0,
      willItRain: json['will_it_rain'] as int? ?? 0,
      willItSnow: json['will_it_snow'] as int? ?? 0,
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
  final List<HourlyForecast> hourlyForecasts; // NEW: Add hourly data

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
    required this.hourlyForecasts, // NEW
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    final day = json['day'];
    final condition = day['condition'];
    final astro = json['astro'];

    // NEW: Parse hourly data
    final hourlyList = (json['hour'] as List?)
        ?.map((hourJson) => HourlyForecast.fromJson(hourJson))
        .toList() ?? [];

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
      hourlyForecasts: hourlyList, // NEW
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

  // NEW: Get all hourly forecasts from all days
  List<HourlyForecast> get allHourlyForecasts {
    final List<HourlyForecast> allHours = [];
    for (var day in forecast) {
      allHours.addAll(day.hourlyForecasts);
    }
    return allHours;
  }

  // NEW: Get today's hourly forecasts
  List<HourlyForecast> get todayHourlyForecasts {
    if (forecast.isEmpty) return [];
    return forecast.first.hourlyForecasts;
  }
}