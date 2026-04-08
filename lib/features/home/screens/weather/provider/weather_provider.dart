// lib/features/home/screens/weather/provider/weather_provider.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

enum WeatherLoadingState {
  idle,
  loading,
  loaded,
  error,
}

enum LocationPermissionState {
  unknown,
  checking,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  // Current weather and forecast data (combined)
  WeatherForecast? _weatherForecast;

  // State management
  WeatherLoadingState _loadingState = WeatherLoadingState.idle;
  LocationPermissionState _permissionState = LocationPermissionState.unknown;
  String? _errorMessage;

  // Location data
  Position? _lastKnownPosition;
  String _selectedCity = 'Islamabad'; // Default fallback city

  bool _isDisposed = false;
  bool _hasInitialized = false; // ✅ ADD THIS - Prevents re-initialization
  DateTime? _lastRefreshTime; // ✅ ADD THIS - Track last refresh

  // ✅ Cache duration - only auto-refresh if data is older than this
  static const Duration _cacheValidDuration = Duration(minutes: 15);

  // Getters
  WeatherModel? get currentWeather => _weatherForecast?.current;
  List<ForecastDay>? get forecastDays => _weatherForecast?.forecast;
  WeatherLoadingState get loadingState => _loadingState;
  LocationPermissionState get permissionState => _permissionState;
  String? get errorMessage => _errorMessage;
  Position? get lastKnownPosition => _lastKnownPosition;
  String get selectedCity => _selectedCity;

  bool get isLoading => _loadingState == WeatherLoadingState.loading;
  bool get hasError => _loadingState == WeatherLoadingState.error;
  bool get hasData => _weatherForecast != null;
  bool get hasForecast => _weatherForecast?.forecast.isNotEmpty ?? false;

  // Permission status helpers
  bool get isLocationGranted => _permissionState == LocationPermissionState.granted;
  bool get isLocationDenied => _permissionState == LocationPermissionState.denied;
  bool get isLocationDeniedForever => _permissionState == LocationPermissionState.deniedForever;
  bool get isLocationServiceDisabled => _permissionState == LocationPermissionState.serviceDisabled;

  // ✅ Check if cache is still valid
  bool get _isCacheValid {
    if (_lastRefreshTime == null || _weatherForecast == null) return false;
    final timeSinceRefresh = DateTime.now().difference(_lastRefreshTime!);
    return timeSinceRefresh < _cacheValidDuration;
  }

  String get permissionStatusMessage {
    switch (_permissionState) {
      case LocationPermissionState.granted:
        return 'Location access granted';
      case LocationPermissionState.denied:
        return 'Location permission denied';
      case LocationPermissionState.deniedForever:
        return 'Location permission permanently denied';
      case LocationPermissionState.serviceDisabled:
        return 'Location services are disabled';
      case LocationPermissionState.checking:
        return 'Checking location permissions...';
      default:
        return 'Location status unknown';
    }
  }

  WeatherProvider() {
    _initialize();
  }

  /// Initialize the weather provider (ONLY ONCE)
  Future<void> _initialize() async {
    if (_hasInitialized) {
      if (kDebugMode) {
        print('⚠️  Weather already initialized, skipping...');
      }
      return;
    }

    if (kDebugMode) {
      print('🌤️  Initializing WeatherProvider...');
    }

    _hasInitialized = true;
    await loadWeatherData();
  }

  /// Main method to load weather data
  Future<void> loadWeatherData({bool forceRefresh = false}) async {
    if (_isDisposed) return;

    // ✅ If cache is valid and not forcing refresh, skip loading
    if (!forceRefresh && _isCacheValid) {
      if (kDebugMode) {
        print('✅ Using cached weather data (still valid)');
      }
      return;
    }

    _updateState(WeatherLoadingState.loading);
    _clearError();

    try {
      // Check location permissions
      await _checkLocationPermission();

      if (_permissionState == LocationPermissionState.granted) {
        // Try to get location-based weather
        await _loadWeatherByLocation();
      } else if (_permissionState == LocationPermissionState.serviceDisabled) {
        // Service disabled - use default city
        await _loadWeatherByCity(_selectedCity);
      } else {
        // Permission denied - use default city
        await _loadWeatherByCity(_selectedCity);
      }

      _updateState(WeatherLoadingState.loaded);
      _lastRefreshTime = DateTime.now(); // ✅ Update refresh time

      if (kDebugMode) {
        print('✅ Weather data loaded successfully');
        _printWeatherDebug();
      }
    } catch (e) {
      _handleError(e);

      if (kDebugMode) {
        print('❌ Failed to load weather: $e');
      }
    }
  }

  /// Check and update location permission status
  Future<void> _checkLocationPermission() async {
    if (_isDisposed) return;

    // ✅ Don't re-check if we already know the status (unless it's unknown)
    if (_permissionState != LocationPermissionState.unknown &&
        _permissionState != LocationPermissionState.checking) {
      if (kDebugMode) {
        print('ℹ️  Using cached permission state: $_permissionState');
      }
      return;
    }

    _safeSetState(() {
      _permissionState = LocationPermissionState.checking;
    });

    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _safeSetState(() {
          _permissionState = LocationPermissionState.serviceDisabled;
        });
        return;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      _safeSetState(() {
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          _permissionState = LocationPermissionState.granted;
        } else if (permission == LocationPermission.deniedForever) {
          _permissionState = LocationPermissionState.deniedForever;
        } else {
          _permissionState = LocationPermissionState.denied;
        }
      });
    } catch (e) {
      _safeSetState(() {
        _permissionState = LocationPermissionState.denied;
      });
      if (kDebugMode) {
        print('⚠️  Location permission check failed: $e');
      }
    }
  }

  /// Load weather by current location
  Future<void> _loadWeatherByLocation() async {
    try {
      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;

      if (kDebugMode) {
        print('📍 Location: ${position.latitude}, ${position.longitude}');
      }

      // Fetch weather and forecast (combined in one API call)
      final forecast = await _weatherService.getWeatherByCoordinates(
        position.latitude,
        position.longitude,
        days: 5,
      );

      if (kDebugMode) {
        print('🕒 LOCAL TIME FROM API: "${forecast.current.localTime}"');
        print('🌍 TIMEZONE FROM API: "${forecast.current.timezone}"');
        print('📍 CITY FROM API: "${forecast.current.cityName}"');
      }

      _safeSetState(() {
        _weatherForecast = forecast;
        _selectedCity = forecast.current.cityName;
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  Location-based weather failed, using default city: $e');
      }
      // Fallback to default city
      await _loadWeatherByCity(_selectedCity);
    }
  }

  /// Load weather by city name
  Future<void> _loadWeatherByCity(String city) async {
    try {
      if (kDebugMode) {
        print('🔍 Searching weather for city: $city');
      }

      final forecast = await _weatherService.getWeatherByCity(city, days: 5);

      if (kDebugMode) {
        print('=== CITY SEARCH RESULT ===');
        print('🏙️  City: ${forecast.current.cityName}');
        print('🌍 Country: ${forecast.current.country}');
        print('🕒 Local Time: "${forecast.current.localTime}"');
        print('⏰ Timezone: "${forecast.current.timezone}"');
        print('🌡️  Temperature: ${forecast.current.temperature}°C');
        print('========================');
      }

      _safeSetState(() {
        _weatherForecast = forecast;
        _selectedCity = forecast.current.cityName;
      });

      if (kDebugMode) {
        print('🏙️  Weather loaded for city: $city');
      }
    } catch (e) {
      throw Exception('Failed to load weather for $city: $e');
    }
  }

  /// ✅ FIXED: Refresh weather data (ONLY when user explicitly requests)
  Future<void> refreshWeather() async {
    if (kDebugMode) {
      print('🔄 User requested refresh - forcing reload...');
    }

    // Clear cache and force reload
    _lastRefreshTime = null;
    await loadWeatherData(forceRefresh: true);
  }

  /// Load weather for a specific city
  Future<void> loadWeatherForCity(String city) async {
    if (_isDisposed) return;

    if (kDebugMode) {
      print('🔍 User requested weather for: $city');
    }

    _updateState(WeatherLoadingState.loading);
    _clearError();

    try {
      await _loadWeatherByCity(city);
      _updateState(WeatherLoadingState.loaded);
      _lastRefreshTime = DateTime.now(); // ✅ Update refresh time

      if (kDebugMode) {
        print('✅ Successfully loaded weather for: $city');
        _printWeatherDebug();
      }
    } catch (e) {
      _handleError(e);
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      // ✅ Reset permission state to force re-check
      _permissionState = LocationPermissionState.unknown;

      await Geolocator.requestPermission();

      await _checkLocationPermission();

      if (_permissionState == LocationPermissionState.granted) {
        await loadWeatherData(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to request permission: $e');
      }
      return false;
    }
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();

    // ✅ After opening settings, reset permission state so it re-checks when user returns
    Future.delayed(const Duration(seconds: 1), () {
      _permissionState = LocationPermissionState.unknown;
    });
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();

    // ✅ After opening settings, reset permission state
    Future.delayed(const Duration(seconds: 1), () {
      _permissionState = LocationPermissionState.unknown;
    });
  }

  /// Use default city weather
  Future<void> useDefaultCity() async {
    await loadWeatherForCity(_selectedCity);
  }

  /// ✅ Manually invalidate cache (useful for debugging)
  void invalidateCache() {
    _lastRefreshTime = null;
    if (kDebugMode) {
      print('🗑️  Weather cache invalidated');
    }
  }

  /// ✅ Get time since last refresh
  String getTimeSinceRefresh() {
    if (_lastRefreshTime == null) return 'Never';

    final duration = DateTime.now().difference(_lastRefreshTime!);

    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes} min ago';
    if (duration.inHours < 24) return '${duration.inHours} hours ago';
    return '${duration.inDays} days ago';
  }

  // Helper methods
  void _updateState(WeatherLoadingState state) {
    _safeSetState(() {
      _loadingState = state;
    });
  }

  void _clearError() {
    _safeSetState(() {
      _errorMessage = null;
    });
  }

  void _handleError(dynamic error) {
    String message;

    if (error is WeatherException) {
      message = error.message;
    } else if (error is Exception) {
      message = error.toString().replaceAll('Exception: ', '');
    } else {
      message = error.toString();
    }

    _safeSetState(() {
      _loadingState = WeatherLoadingState.error;
      _errorMessage = message;
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (_isDisposed) return;
    fn();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _printWeatherDebug() {
    if (_weatherForecast == null) return;

    print('=== CURRENT WEATHER STATE ===');
    print('🏙️  City: ${_weatherForecast!.current.cityName}');
    print('🌍 Country: ${_weatherForecast!.current.country}');
    print('🕒 Local Time: "${_weatherForecast!.current.localTime}"');
    print('⏰ Timezone: "${_weatherForecast!.current.timezone}"');
    print('🌡️  Temperature: ${_weatherForecast!.current.temperature}°C');
    print('☁️  Condition: ${_weatherForecast!.current.conditionText}');
    print('💧 Humidity: ${_weatherForecast!.current.humidity}%');
    print('💨 Wind Speed: ${_weatherForecast!.current.windSpeed} km/h');
    print('☀️  UV Index: ${_weatherForecast!.current.uvIndex}');
    print('📅 Forecast Days: ${_weatherForecast!.forecast.length}');
    print('🔄 Last Refresh: ${getTimeSinceRefresh()}');
    print('💾 Cache Valid: ${_isCacheValid ? "Yes" : "No"}');
    print('============================');
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (kDebugMode) {
      print('🗑️  WeatherProvider disposed');
    }
    super.dispose();
  }
}

// ✅ Custom exception for weather-related errors
class WeatherException implements Exception {
  final String message;

  WeatherException(this.message);

  @override
  String toString() => message;
}