import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey = '5ccb6e1680064a169e5113329251608';
  static const String _baseUrl = 'https://api.weatherapi.com/v1';
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _cacheDuration = Duration(minutes: 10); // Cache for 10 minutes

  // Singleton pattern
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // Cache storage
  WeatherForecast? _cachedForecast;
  DateTime? _lastFetchTime;
  String? _lastQuery;
  int? _lastDays;

  /// Check if cached data is still valid
  bool _isCacheValid(String query, int days) {
    if (_cachedForecast == null || _lastFetchTime == null) {
      return false;
    }

    final cacheAge = DateTime.now().difference(_lastFetchTime!);
    final isSameQuery = _lastQuery == query && _lastDays == days;

    return isSameQuery && cacheAge < _cacheDuration;
  }

  /// Clear the cache manually if needed
  void clearCache() {
    _cachedForecast = null;
    _lastFetchTime = null;
    _lastQuery = null;
    _lastDays = null;
    if (kDebugMode) {
      print('🗑️ Weather cache cleared');
    }
  }

  /// Get current weather with forecast by city name
  Future<WeatherForecast> getWeatherByCity(String city, {int days = 5, bool forceRefresh = false}) async {
    try {
      if (city.trim().isEmpty) {
        throw WeatherException('City name cannot be empty');
      }

      if (days < 1 || days > 10) {
        throw WeatherException('Forecast days must be between 1 and 10');
      }

      // Check cache first
      final query = city.toLowerCase().trim();
      if (!forceRefresh && _isCacheValid(query, days)) {
        if (kDebugMode) {
          print('📦 Returning cached weather data for $city');
        }
        return _cachedForecast!;
      }

      if (kDebugMode) {
        print('🌐 Fetching fresh weather data for $city');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/forecast.json?key=$_apiKey&q=$city&days=$days&aqi=yes'),
      ).timeout(_timeout);

      final forecast = _parseForecastResponse(response);

      // Update cache
      _cachedForecast = forecast;
      _lastFetchTime = DateTime.now();
      _lastQuery = query;
      _lastDays = days;

      return forecast;
    } on TimeoutException {
      throw WeatherException('Request timed out. Please check your internet connection.');
    } on http.ClientException catch (e) {
      throw WeatherException('Network error: ${e.message}');
    } catch (e) {
      if (e is WeatherException) rethrow;
      throw WeatherException('Failed to fetch weather: ${e.toString()}');
    }
  }

  /// Get current weather with forecast by coordinates
  Future<WeatherForecast> getWeatherByCoordinates(
      double lat,
      double lon, {
        int days = 5,
        bool forceRefresh = false,
      }) async {
    try {
      if (lat.abs() > 90 || lon.abs() > 180) {
        throw WeatherException('Invalid coordinates provided');
      }

      if (days < 1 || days > 10) {
        throw WeatherException('Forecast days must be between 1 and 10');
      }

      // Check cache first
      final query = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
      if (!forceRefresh && _isCacheValid(query, days)) {
        if (kDebugMode) {
          print('📦 Returning cached weather data for coordinates');
        }
        return _cachedForecast!;
      }

      if (kDebugMode) {
        print('🌐 Fetching fresh weather data for coordinates');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/forecast.json?key=$_apiKey&q=$lat,$lon&days=$days&aqi=yes'),
      ).timeout(_timeout);

      final forecast = _parseForecastResponse(response);

      // Update cache
      _cachedForecast = forecast;
      _lastFetchTime = DateTime.now();
      _lastQuery = query;
      _lastDays = days;

      return forecast;
    } on TimeoutException {
      throw WeatherException('Request timed out. Please check your internet connection.');
    } on http.ClientException catch (e) {
      throw WeatherException('Network error: ${e.message}');
    } catch (e) {
      if (e is WeatherException) rethrow;
      throw WeatherException('Failed to fetch weather: ${e.toString()}');
    }
  }


  WeatherForecast _parseForecastResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(response.body);

        if (kDebugMode) {
          print('✅ Weather & Forecast API Response received');
          print('   Current temp: ${jsonData['current']['temp_c']}°C');
          print('   Forecast days: ${jsonData['forecast']?['forecastday']?.length ?? 0}');
        }

        return WeatherForecast.fromJson(jsonData);
      } catch (e) {
        throw WeatherException('Failed to parse weather data: ${e.toString()}');
      }
    } else {
      throw _handleApiError(response);
    }
  }

  WeatherException _handleApiError(http.Response response) {
    final statusCode = response.statusCode;
    String errorMessage;

    try {
      final errorData = json.decode(response.body);
      errorMessage = errorData['error']?['message'] ?? _getDefaultErrorMessage(statusCode);
    } catch (_) {
      errorMessage = _getDefaultErrorMessage(statusCode);
    }

    if (kDebugMode) {
      print('❌ API Error [$statusCode]: $errorMessage');
    }

    return WeatherException(errorMessage);
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Invalid API key. Please contact support.';
      case 403:
        return 'Access denied. API key may be disabled.';
      case 404:
        return 'Location not found. Please try a different location.';
      case 429:
        return 'Too many requests. Please try again in a few minutes.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Weather service is temporarily unavailable. Please try again later.';
      default:
        return 'An unexpected error occurred (Code: $statusCode)';
    }
  }
}

/// Custom exception for weather-related errors
class WeatherException implements Exception {
  final String message;

  WeatherException(this.message);

  @override
  String toString() => message;
}