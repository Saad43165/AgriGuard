import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../models/air_quality_model.dart';

class WeatherService {
  static const String _apiKey = '5ccb6e1680064a169e5113329251608';
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  Future<WeatherModel> getWeatherByCity(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$city&aqi=yes'),
      ).timeout(const Duration(seconds: 10));

      return _parseWeatherResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<WeatherModel> getWeatherByCoordinates(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$lat,$lon&aqi=yes'),
      ).timeout(const Duration(seconds: 10));

      return _parseWeatherResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  WeatherModel _parseWeatherResponse(http.Response response) {
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final location = jsonData['location'];
      final current = jsonData['current'];
      final condition = current['condition'];

      // Debug print to see the actual API response
      if (kDebugMode) {
        print('Weather API Response: ${json.encode(current)}');
      }

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
    } else {
      throw _handleApiError(response);
    }
  }

  Future<AirQualityModel?> getAirQuality(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$lat,$lon&aqi=yes'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['current']['air_quality'] != null) {
          return AirQualityModel.fromJson(jsonData['current']['air_quality']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Exception _handleError(dynamic e) {
    if (e is http.ClientException) {
      return Exception('Network error: ${e.message}');
    } else if (e.toString().contains('TimeoutException')) {
      return Exception('Request timed out. Please check your internet connection.');
    } else {
      return Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Exception _handleApiError(http.Response response) {
    final statusCode = response.statusCode;
    String errorMessage;

    switch (statusCode) {
      case 400:
        errorMessage = 'Bad request - invalid parameters';
        break;
      case 401:
        errorMessage = 'Unauthorized - invalid API key';
        break;
      case 403:
        errorMessage = 'Forbidden - access denied';
        break;
      case 404:
        errorMessage = 'Location not found';
        break;
      case 429:
        errorMessage = 'Rate limit exceeded - try again later';
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        errorMessage = 'Server error - try again later';
        break;
      default:
        errorMessage = 'API request failed with status $statusCode';
    }

    return Exception(errorMessage);
  }
}