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