import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  WeatherModel? _weather;
  bool _isLoading = false;
  String _error = '';
  String _locationPermissionStatus = '';
  bool _isDisposed = false;

  WeatherModel? get weather => _weather;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get locationPermissionStatus => _locationPermissionStatus;

  WeatherProvider() {
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    if (_isDisposed) return;

    _safeSetState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Please enable it in app settings.');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Get weather by coordinates
      final weather = await _weatherService.getWeatherByCoordinates(
          position.latitude,
          position.longitude
      );

      _safeSetState(() {
        _weather = weather;
        _locationPermissionStatus = 'Permission granted';
      });
    } catch (e) {
      _safeSetState(() {
        _error = e.toString();
        _locationPermissionStatus = 'Error: ${e.toString()}';
      });
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> refreshWeather() async {
    await _loadWeatherData();
  }

  void _safeSetState(VoidCallback fn) {
    if (_isDisposed) return;
    fn();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}