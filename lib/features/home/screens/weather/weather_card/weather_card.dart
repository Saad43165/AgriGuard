import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/constants/app_measurements.dart';
import '../provider/weather_provider.dart';
import '../weather_screen/widgets/weather_details_screen.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return _buildLoadingCard(context);
        }

        if (provider.hasError && !provider.hasData) {
          return _buildErrorCard(context, provider);
        }

        if (provider.hasData) {
          return _buildWeatherCard(context, provider);
        }

        return _buildErrorCard(context, provider);
      },
    );
  }

  Widget _buildWeatherCard(BuildContext context, WeatherProvider provider) {
    final weatherData = provider.currentWeather!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weatherColor = _getWeatherColor(weatherData.conditionText, weatherData.isDay, isDark);
    final gradientColors = _getGradientColors(weatherData.conditionText, weatherData.isDay, isDark);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Container(
      height: 175,
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: weatherColor.withOpacity(isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : weatherColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Dynamic Weather Background
            ..._buildWeatherBackground(weatherData.conditionText, weatherData.isDay),

            // Main Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeatherDetailsScreen(
                        weatherData: weatherData,
                        forecastDays: provider.forecastDays,
                        weatherColor: weatherColor,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Location
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        weatherData.cityName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        _getLocationTime(provider),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons
                          Row(
                            children: [
                              _buildActionButton(
                                context,
                                Icons.search_rounded,
                                    () => _showSearchDialog(context, provider, weatherColor),
                              ),
                              const SizedBox(width: 6),
                              _buildActionButton(
                                context,
                                provider.isLoading ? null : Icons.refresh_rounded,
                                provider.isLoading ? null : () => provider.refreshWeather(),
                                isLoading: provider.isLoading,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Main Content
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Temperature Side
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        weatherData.temperature.toStringAsFixed(0),
                                        style: const TextStyle(
                                          fontSize: 44,
                                          fontWeight: FontWeight.w300,
                                          height: 0.9,
                                          color: Colors.white,
                                          letterSpacing: -2,
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Text(
                                          '°C',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w300,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Feels ${weatherData.feelsLike.toStringAsFixed(0)}°',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Weather Icon & Condition
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getWeatherIcon(weatherData.conditionText, weatherData.isDay),
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    weatherData.conditionText,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Bottom Metrics
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetric(Icons.water_drop_rounded, '${weatherData.humidity}%'),
                            _buildDivider(),
                            _buildMetric(Icons.air_rounded, '${weatherData.windSpeed.toStringAsFixed(0)}'),
                            _buildDivider(),
                            _buildMetric(Icons.wb_sunny_rounded, '${weatherData.uvIndex.toStringAsFixed(1)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dynamic Weather Background Elements
  List<Widget> _buildWeatherBackground(String condition, int isDay) {
    final lowerCondition = condition.toLowerCase();

    // Sunny/Clear Day
    if (isDay == 1 && (lowerCondition.contains('sunny') || lowerCondition.contains('clear'))) {
      return [
        // Sun rays
        Positioned(
          top: -20,
          right: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.yellow.withOpacity(0.2),
                  Colors.orange.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Small sun particles
        ...List.generate(8, (index) {
          return Positioned(
            top: (index % 3) * 50.0 + 10,
            left: (index % 4) * 70.0 + 20,
            child: Icon(
              Icons.wb_sunny_outlined,
              size: 18,
              color: Colors.white.withOpacity(0.1),
            ),
          );
        }),
      ];
    }

    // Clear Night
    if (isDay == 0 && lowerCondition.contains('clear')) {
      return [
        // Moon
        Positioned(
          top: 15,
          right: 20,
          child: Icon(
            Icons.nightlight_round,
            size: 50,
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        // Stars
        ...List.generate(12, (index) {
          return Positioned(
            top: (index % 4) * 40.0 + 10,
            left: (index % 5) * 60.0 + 15,
            child: Icon(
              Icons.star,
              size: 8 + (index % 3) * 2,
              color: Colors.white.withOpacity(0.2),
            ),
          );
        }),
      ];
    }

    // Rainy
    if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
      return [
        // Rain drops
        ...List.generate(15, (index) {
          return Positioned(
            top: (index % 5) * 35.0,
            left: (index % 4) * 70.0 + (index % 2) * 30,
            child: Icon(
              Icons.water_drop,
              size: 12 + (index % 3) * 2,
              color: Colors.white.withOpacity(0.15),
            ),
          );
        }),
      ];
    }

    // Stormy/Thunderstorm
    if (lowerCondition.contains('storm') || lowerCondition.contains('thunder')) {
      return [
        // Dark clouds
        Positioned(
          top: 10,
          left: 30,
          child: Icon(
            Icons.cloud,
            size: 60,
            color: Colors.black.withOpacity(0.2),
          ),
        ),
        Positioned(
          top: 20,
          right: 40,
          child: Icon(
            Icons.cloud,
            size: 50,
            color: Colors.black.withOpacity(0.15),
          ),
        ),
        // Lightning bolts
        ...List.generate(3, (index) {
          return Positioned(
            top: (index % 2) * 60.0 + 30,
            left: (index % 3) * 90.0 + 40,
            child: Icon(
              Icons.flash_on,
              size: 20,
              color: Colors.yellow.withOpacity(0.2),
            ),
          );
        }),
      ];
    }

    // Cloudy
    if (lowerCondition.contains('cloudy') || lowerCondition.contains('overcast')) {
      return [
        // Multiple clouds
        ...List.generate(6, (index) {
          return Positioned(
            top: (index % 3) * 50.0 + 5,
            left: (index % 3) * 80.0 + 10,
            child: Icon(
              Icons.cloud,
              size: 40 + (index % 2) * 10,
              color: Colors.white.withOpacity(0.12),
            ),
          );
        }),
      ];
    }

    // Snowy
    if (lowerCondition.contains('snow') || lowerCondition.contains('sleet')) {
      return [
        // Snowflakes
        ...List.generate(18, (index) {
          return Positioned(
            top: (index % 5) * 35.0,
            left: (index % 4) * 65.0 + (index % 3) * 20,
            child: Icon(
              Icons.ac_unit,
              size: 10 + (index % 3) * 3,
              color: Colors.white.withOpacity(0.2),
            ),
          );
        }),
      ];
    }

    // Foggy/Misty
    if (lowerCondition.contains('fog') || lowerCondition.contains('mist')) {
      return [
        // Fog layers
        ...List.generate(4, (index) {
          return Positioned(
            top: index * 40.0 + 10,
            left: 0,
            right: 0,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          );
        }),
      ];
    }

    // Default - subtle pattern
    return [
      Positioned.fill(
        child: CustomPaint(
          painter: _WeatherPatternPainter(color: Colors.white.withOpacity(0.05)),
        ),
      ),
    ];
  }

  Widget _buildActionButton(BuildContext context, IconData? icon, VoidCallback? onTap, {bool isLoading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 12),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 14,
      color: Colors.white.withOpacity(0.3),
    );
  }

  String _getLocationTime(WeatherProvider provider) {
    final weatherData = provider.currentWeather;

    if (weatherData?.localTime != null && weatherData!.localTime.isNotEmpty) {
      try {
        // Parse the localTime string (format: "2025-02-16 14:30")
        final localDateTime = DateTime.parse(weatherData.localTime);
        final hour = localDateTime.hour.toString().padLeft(2, '0');
        final minute = localDateTime.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      } catch (e) {
        // If parsing fails, fallback to current time
        return _getCurrentTime();
      }
    }

    // Fallback to device time if location time not available
    return _getCurrentTime();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showSearchDialog(BuildContext context, WeatherProvider provider, Color weatherColor) {
    final searchController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        bool isSearching = false;
        String? error;

        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [weatherColor, weatherColor.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Enter city name...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.shade500,
                      ),
                      prefixIcon: Icon(Icons.location_city_rounded, color: weatherColor, size: 20),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: isDark ? Colors.white70 : Colors.grey),
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: isDark ? weatherColor.withOpacity(0.15) : weatherColor.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: weatherColor.withOpacity(0.2), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: weatherColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1),
                      ),
                      errorText: error,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (value) => _performSearch(
                      value,
                      provider,
                      modalContext,
                      setState,
                          () => isSearching,
                          (val) => isSearching = val,
                          (val) => error = val,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSearching
                          ? null
                          : () => _performSearch(
                        searchController.text,
                        provider,
                        modalContext,
                        setState,
                            () => isSearching,
                            (val) => isSearching = val,
                            (val) => error = val,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: weatherColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        disabledBackgroundColor: weatherColor.withOpacity(0.5),
                      ),
                      child: isSearching
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _performSearch(
      String value,
      WeatherProvider provider,
      BuildContext modalContext,
      StateSetter setState,
      bool Function() getSearching,
      void Function(bool) setSearching,
      void Function(String?) setError,
      ) async {
    if (value.trim().isEmpty) {
      setState(() => setError('Please enter a city name'));
      return;
    }
    setState(() {
      setSearching(true);
      setError(null);
    });
    try {
      await provider.loadWeatherForCity(value.trim());
      if (modalContext.mounted) Navigator.pop(modalContext);
    } catch (e) {
      setState(() {
        setError(e.toString().replaceAll('Exception: ', ''));
        setSearching(false);
      });
    }
  }

  Widget _buildLoadingCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: 150,
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [primaryColor.withOpacity(0.2), primaryColor.withOpacity(0.1)]
              : [primaryColor.withOpacity(0.15), primaryColor.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(isDark ? 0.3 : 0.2), width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading Weather...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryColor,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WeatherProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = provider.isLocationDenied || provider.isLocationDeniedForever
        ? Theme.of(context).colorScheme.error
        : (isDark ? Colors.orange.shade400 : Colors.orange.shade700);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Container(
      height: 150,
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [errorColor.withOpacity(0.2), errorColor.withOpacity(0.1)]
              : [errorColor.withOpacity(0.15), errorColor.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: errorColor.withOpacity(isDark ? 0.4 : 0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleErrorTap(context, provider),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getErrorIcon(provider), size: 28, color: errorColor),
                ),
                const SizedBox(height: 10),
                Text(
                  _getErrorTitle(provider),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: errorColor,
                    fontSize: 15,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _getErrorMessage(provider),
                  style: TextStyle(
                    color: isDark ? errorColor.withOpacity(0.8) : errorColor.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getErrorIcon(WeatherProvider provider) {
    if (provider.isLocationDenied || provider.isLocationDeniedForever) {
      return Icons.location_off_rounded;
    } else if (provider.isLocationServiceDisabled) {
      return Icons.location_disabled_rounded;
    }
    return Icons.cloud_off_rounded;
  }

  String _getErrorTitle(WeatherProvider provider) {
    if (provider.isLocationDeniedForever) return 'Permission Required';
    if (provider.isLocationDenied) return 'Location Required';
    if (provider.isLocationServiceDisabled) return 'Location Services Off';
    return 'Weather Unavailable';
  }

  String _getErrorMessage(WeatherProvider provider) {
    if (provider.isLocationDeniedForever) return 'Tap to open settings';
    if (provider.isLocationDenied) return 'Tap to grant access';
    if (provider.isLocationServiceDisabled) return 'Tap to enable services';
    return provider.errorMessage ?? 'Tap to retry';
  }

  void _handleErrorTap(BuildContext context, WeatherProvider provider) {
    if (provider.isLocationServiceDisabled) {
      provider.openLocationSettings();
    } else if (provider.isLocationDeniedForever) {
      provider.openAppSettings();
    } else if (provider.isLocationDenied) {
      provider.requestLocationPermission();
    } else {
      provider.refreshWeather();
    }
  }

  IconData _getWeatherIcon(String condition, int isDay) {
    final lowerCondition = condition.toLowerCase();
    if (isDay == 0) {
      if (lowerCondition.contains('clear')) return Icons.nightlight_round;
      if (lowerCondition.contains('cloudy') || lowerCondition.contains('overcast')) return Icons.cloud;
    }
    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) {
      return Icons.wb_sunny_rounded;
    } else if (lowerCondition.contains('cloudy') || lowerCondition.contains('overcast')) {
      return Icons.cloud_rounded;
    } else if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
      return Icons.water_drop_rounded;
    } else if (lowerCondition.contains('storm') || lowerCondition.contains('thunder')) {
      return Icons.thunderstorm_rounded;
    } else if (lowerCondition.contains('snow') || lowerCondition.contains('sleet')) {
      return Icons.ac_unit_rounded;
    } else if (lowerCondition.contains('fog') || lowerCondition.contains('mist')) {
      return Icons.foggy;
    }
    return Icons.wb_cloudy_rounded;
  }

  Color _getWeatherColor(String condition, int isDay, bool isDark) {
    final lowerCondition = condition.toLowerCase();
    if (isDay == 0) {
      if (lowerCondition.contains('clear')) {
        return isDark ? const Color(0xFF3949AB) : const Color(0xFF1a237e);
      } else if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
        return isDark ? const Color(0xFF455A64) : const Color(0xFF263238);
      } else if (lowerCondition.contains('storm') || lowerCondition.contains('thunder')) {
        return isDark ? const Color(0xFF512DA8) : const Color(0xFF311b92);
      } else if (lowerCondition.contains('snow') || lowerCondition.contains('sleet')) {
        return isDark ? const Color(0xFF546E7A) : const Color(0xFF37474f);
      } else if (lowerCondition.contains('cloudy') || lowerCondition.contains('overcast')) {
        return isDark ? const Color(0xFF616161) : const Color(0xFF424242);
      }
      return isDark ? const Color(0xFF5C6BC0) : const Color(0xFF283593);
    }
    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) {
      return isDark ? const Color(0xFFFF9800) : const Color(0xFFEF6C00);
    } else if (lowerCondition.contains('cloudy') || lowerCondition.contains('overcast')) {
      return isDark ? const Color(0xFF78909C) : const Color(0xFF546E7A);
    } else if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
      return isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    } else if (lowerCondition.contains('storm') || lowerCondition.contains('thunder')) {
      return isDark ? const Color(0xFF7E57C2) : const Color(0xFF512DA8);
    } else if (lowerCondition.contains('snow') || lowerCondition.contains('sleet')) {
      return isDark ? const Color(0xFF4FC3F7) : const Color(0xFF0288D1);
    }
    return isDark ? const Color(0xFF26A69A) : const Color(0xFF00897B);
  }

  List<Color> _getGradientColors(String condition, int isDay, bool isDark) {
    final baseColor = _getWeatherColor(condition, isDay, isDark);
    return [baseColor, baseColor.withOpacity(0.85)];
  }
}

// Custom Painter for Default Pattern
class _WeatherPatternPainter extends CustomPainter {
  final Color color;

  _WeatherPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;

    for (var i = 0; i < 5; i++) {
      for (var j = 0; j < 4; j++) {
        canvas.drawCircle(
          Offset(i * size.width / 4, j * size.height / 3),
          15,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}