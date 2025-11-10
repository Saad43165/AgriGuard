import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'models/weather_model.dart';
import 'services/weather_service.dart';
import 'widgets/weather_details_dialog.dart';
import 'widgets/weather_icon.dart';
import 'widgets/weather_metrices_row.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final WeatherService _weatherService = WeatherService();
  WeatherModel? _weather;
  bool _isLoading = true;
  String _error = '';
  bool _locationDenied = false;
  bool _serviceDisabled = false;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = '';
      _locationDenied = false;
      _serviceDisabled = false;
    });

    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _serviceDisabled = true;
          _error = 'Location services are disabled';
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationDenied = true;
            _error = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationDenied = true;
          _error = 'Location permission permanently denied';
        });
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 10));

      print('=== LOCATION DEBUG ===');
      print('Latitude: ${position.latitude}');
      print('Longitude: ${position.longitude}');
      print('======================');

      // Get weather by coordinates
      final weather = await _weatherService
          .getWeatherByCoordinates(position.latitude, position.longitude)
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
        });

        // DEBUG: Print all weather data
        _printWeatherDebugInfo(weather);
        _debugApiResponse(); // ADD THIS LINE
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = 'Request timed out. Check your internet connection.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  // DEBUG METHOD: Print all weather data to console
  void _printWeatherDebugInfo(WeatherModel weather) {
    print('=== WEATHER DATA DEBUG ===');
    print('City: ${weather.cityName}');
    print('Temperature: ${weather.temperature}°C');
    print('Feels Like: ${weather.feelsLike}°C');
    print('Condition: ${weather.conditionText}');
    print('Humidity: ${weather.humidity}%');
    print('Wind Speed: ${weather.windSpeed} km/h');
    print('Wind Direction: ${weather.windDirection}');
    print('Pressure: ${weather.pressure} hPa');
    print('UV Index: ${weather.uvIndex}');
    print('Cloud Cover: ${weather.cloudCover}%');
    print('Precipitation: ${weather.precipitation} mm');
    print('Visibility: ${weather.visibilityKm} km');
    print('Gust Speed: ${weather.gustSpeed} km/h');
    print('Is Day: ${weather.isDay}');
    print('Last Updated: ${weather.lastUpdated}');
    print('==========================');
  }

  Future<void> _handlePermissionRequest() async {
    if (!mounted) return;

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      // Open app settings for permanently denied
      await _showPermissionDialog(isPermanentlyDenied: true);
    } else if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Permission granted, reload weather
        await _loadWeatherData();
      } else {
        // Still denied, show dialog
        await _showPermissionDialog(isPermanentlyDenied: false);
      }
    } else {
      // Permission already granted, reload
      await _loadWeatherData();
    }
  }

  Future<void> _showPermissionDialog({required bool isPermanentlyDenied}) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    isPermanentlyDenied
                        ? 'Location Access Required'
                        : 'Enable Location',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    isPermanentlyDenied
                        ? 'Location permission is permanently denied. Please enable it in app settings to see local weather.'
                        : 'Weather information requires location access to show accurate local data.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Column(
                    children: [
                      if (isPermanentlyDenied)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await Geolocator.openAppSettings();
                            },
                            icon: const Icon(Icons.settings_rounded),
                            label: const Text('Open Settings'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _useDefaultLocation();
                          },
                          icon: const Icon(Icons.location_city_rounded),
                          label: const Text('Use Default City'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _useDefaultLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final defaultWeather = await _weatherService
          .getWeatherByCity('Islamabad')
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _weather = defaultWeather;
          _locationDenied = false;
          _isLoading = false;
        });

        // DEBUG: Print default weather data
        _printWeatherDebugInfo(defaultWeather);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load default weather: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Color _getWeatherColor(String condition) {
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) {
      return const Color(0xFFFF9800);
    } else if (lowerCondition.contains('cloudy') ||
        lowerCondition.contains('overcast')) {
      return const Color(0xFF9E9E9E);
    } else if (lowerCondition.contains('rain') ||
        lowerCondition.contains('drizzle')) {
      return const Color(0xFF2196F3);
    } else if (lowerCondition.contains('storm') ||
        lowerCondition.contains('thunder')) {
      return const Color(0xFF673AB7);
    } else if (lowerCondition.contains('snow') ||
        lowerCondition.contains('sleet')) {
      return const Color(0xFF03A9F4);
    } else if (lowerCondition.contains('fog') ||
        lowerCondition.contains('mist')) {
      return const Color(0xFF607D8B);
    } else {
      return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: Print current state
    print('=== WEATHER CARD STATE ===');
    print('Loading: $_isLoading');
    print('Error: $_error');
    print('Location Denied: $_locationDenied');
    print('Service Disabled: $_serviceDisabled');
    print('Weather Data: ${_weather != null ? "Available" : "Null"}');
    if (_weather != null) {
      print('Current City: ${_weather!.cityName}');
      print('Current Temp: ${_weather!.temperature}°C');
    }
    print('==========================');

    if (_isLoading) {
      return _buildLoadingCard(context);
    }

    if (_weather == null || _error.isNotEmpty) {
      return _buildErrorCard(context);
    }

    final weatherData = _weather!;
    final weatherColor = _getWeatherColor(weatherData.conditionText);

    return Container(
      margin: const EdgeInsets.symmetric(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
        ),
        border: Border.all(
          color: weatherColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: weatherColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => WeatherDetailsDialog(
                weatherData: weatherData,
                weatherColor: weatherColor,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // Weather Icon
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            weatherColor.withOpacity(0.3),
                            weatherColor.withOpacity(0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: weatherColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: WeatherIcon(
                        condition: weatherData.conditionText,
                        size: 36,
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Temperature & Condition
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${weatherData.temperature.toStringAsFixed(0)}°',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                  AppMeasurements.getResponsiveFontSize(
                                    context,
                                    baseSize: 42,
                                  ),
                                  height: 1,
                                  color: weatherColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'C',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    color: weatherColor.withOpacity(0.7),
                                    fontSize:
                                    AppMeasurements.getResponsiveFontSize(
                                      context,
                                      baseSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weatherData.conditionText,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                              fontSize:
                              AppMeasurements.getResponsiveFontSize(
                                context,
                                baseSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Location
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: weatherColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: weatherColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          weatherData.cityName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontSize: AppMeasurements.getResponsiveFontSize(
                              context,
                              baseSize: 13,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Divider
                Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        weatherColor.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Weather Metrics
                WeatherMetricsRow(
                  humidity: weatherData.humidity,
                  windSpeed: weatherData.windSpeed,
                  uvIndex: weatherData.uvIndex,
                  weatherColor: weatherColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppMeasurements.defaultPadding),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                ],
              ),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loading Weather...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Getting your location',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final errorColor = _locationDenied || _serviceDisabled
        ? Theme.of(context).colorScheme.error
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppMeasurements.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
        ),
        border: Border.all(
          color: errorColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
          ),
          onTap: _serviceDisabled
              ? () async => await Geolocator.openLocationSettings()
              : _locationDenied
              ? _handlePermissionRequest
              : _loadWeatherData,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        errorColor.withOpacity(0.2),
                        errorColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    _locationDenied
                        ? Icons.location_off_rounded
                        : _serviceDisabled
                        ? Icons.location_disabled_rounded
                        : Icons.error_outline_rounded,
                    size: 32,
                    color: errorColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationDenied
                            ? 'Location Required'
                            : _serviceDisabled
                            ? 'Location Services Off'
                            : 'Weather Unavailable',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: errorColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _locationDenied
                            ? 'Tap to enable location access'
                            : _serviceDisabled
                            ? 'Tap to enable location services'
                            : 'Tap to retry',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color: errorColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Add this method to debug the API response
  void _debugApiResponse() {
    print('=== API RESPONSE ANALYSIS ===');
    if (_weather != null) {
      print('UV Index from API: ${_weather!.uvIndex}');
      print('Cloud Cover from API: ${_weather!.cloudCover}%');
      print('Precipitation from API: ${_weather!.precipitation}mm');
      print('Visibility from API: ${_weather!.visibilityKm}km');
      print('Gust Speed from API: ${_weather!.gustSpeed}km/h');

      // Check if these values are actually 0 or if there's an issue
      if (_weather!.uvIndex == 0.0) {
        print('⚠️  UV Index is 0 - this might be missing from API response');
      }
      if (_weather!.cloudCover == 0) {
        print('⚠️  Cloud Cover is 0 - this might be missing from API response');
      }
      if (_weather!.precipitation == 0.0) {
        print('⚠️  Precipitation is 0 - this might be missing from API response');
      }
    } else {
      print('Weather data is null');
    }
    print('============================');
  }
}