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
    final weatherColor = _getWeatherColor(weatherData.conditionText, weatherData.isDay);
    final responsivePadding = AppMeasurements.getResponsivePadding(context);
    final responsiveSmallPadding = AppMeasurements.getResponsiveSmallPadding(context);

    return Container(
      height: AppMeasurements.getResponsiveHeight(context, baseHeight: 215),
      margin: EdgeInsets.symmetric(horizontal: responsivePadding * 0.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            weatherColor,
            weatherColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context) * 3),
        boxShadow: [
          BoxShadow(
            color: weatherColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context) * 3),
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
          child: Stack(
            children: [
              // Animated background particles
              ..._buildBackgroundParticles(weatherData.conditionText),

              // Main Content
              Padding(
                padding: EdgeInsets.all(responsivePadding * 0.85),
                child: Column(
                  children: [
                    // Top Row - Location and Search Bar
                    Row(
                      children: [
                        // Location
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: AppMeasurements.getResponsiveIconSizeSmall(context) + 2,
                              ),
                              SizedBox(width: responsiveSmallPadding * 0.25),
                              Expanded(
                                child: Text(
                                  weatherData.cityName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 15),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: responsiveSmallPadding),
                        // Compact Search Bar
                        GestureDetector(
                          onTap: () => _showSearchDialog(context, provider, weatherColor),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsiveSmallPadding,
                              vertical: responsiveSmallPadding * 0.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: AppMeasurements.getResponsiveIconSizeSmall(context),
                                ),
                                SizedBox(width: responsiveSmallPadding * 0.5),
                                Text(
                                  'Search',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 13),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: responsiveSmallPadding * 0.5),
                        // Refresh Button
                        GestureDetector(
                          onTap: provider.isLoading ? null : () => provider.refreshWeather(),
                          child: Container(
                            padding: EdgeInsets.all(responsiveSmallPadding * 0.6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: provider.isLoading
                                ? SizedBox(
                              width: AppMeasurements.getResponsiveIconSizeSmall(context),
                              height: AppMeasurements.getResponsiveIconSizeSmall(context),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: AppMeasurements.getResponsiveIconSizeSmall(context) + 2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Middle - Temperature and Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left side - Temperature
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weatherData.temperature.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 64),
                                fontWeight: FontWeight.w200,
                                height: 1,
                                color: Colors.white,
                                letterSpacing: -2,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: responsiveSmallPadding * 0.3),
                              child: Text(
                                '°',
                                style: TextStyle(
                                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 32),
                                  fontWeight: FontWeight.w200,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: responsivePadding),
                        // Right side - Icon and condition
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getWeatherIcon(weatherData.conditionText, weatherData.isDay),
                              size: AppMeasurements.getResponsiveIconSizeLarge(context) * 0.7,
                              color: Colors.white.withOpacity(0.95),
                            ),
                            SizedBox(height: responsiveSmallPadding * 0.3),
                            Text(
                              weatherData.conditionText,
                              style: TextStyle(
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Feels ${weatherData.feelsLike.toStringAsFixed(0)}°',
                              style: TextStyle(
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Bottom - Weather Metrics
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsivePadding * 0.6,
                        vertical: responsiveSmallPadding * 0.8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context) * 2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInlineMetric(
                            context,
                            Icons.water_drop_rounded,
                            '${weatherData.humidity}%',
                            'Humidity',
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildInlineMetric(
                            context,
                            Icons.air_rounded,
                            weatherData.windSpeed.toStringAsFixed(0),
                            'Wind',
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildInlineMetric(
                            context,
                            Icons.wb_sunny_rounded,
                            weatherData.uvIndex.toStringAsFixed(1),
                            'UV',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundParticles(String condition) {
    final lowerCondition = condition.toLowerCase();
    IconData particleIcon;
    int count;

    if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
      particleIcon = Icons.water_drop;
      count = 6;
    } else if (lowerCondition.contains('snow') || lowerCondition.contains('sleet')) {
      particleIcon = Icons.ac_unit;
      count = 8;
    } else if (lowerCondition.contains('cloud')) {
      particleIcon = Icons.cloud;
      count = 3;
    } else {
      return [];
    }

    return List.generate(count, (index) {
      return Positioned(
        left: (index % 3) * 100.0 + 20,
        top: (index ~/ 3) * 70.0 + 10,
        child: Opacity(
          opacity: 0.1,
          child: Icon(
            particleIcon,
            size: 18,
            color: Colors.white,
          ),
        ),
      );
    });
  }

  Widget _buildInlineMetric(BuildContext context, IconData icon, String value, String label) {
    final responsiveSmallPadding = AppMeasurements.getResponsiveSmallPadding(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: AppMeasurements.getResponsiveIconSizeSmall(context) + 4,
        ),
        SizedBox(width: responsiveSmallPadding * 0.5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 10),
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSearchDialog(BuildContext context, WeatherProvider provider, Color weatherColor) {
    final searchController = TextEditingController();
    final responsivePadding = AppMeasurements.getResponsivePadding(context);
    final responsiveSmallPadding = AppMeasurements.getResponsiveSmallPadding(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        bool isSearching = false;
        String? error;

        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: EdgeInsets.all(responsivePadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppMeasurements.getResponsiveBorderRadius(context) * 3.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: responsiveSmallPadding),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Search for a city...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: weatherColor,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: weatherColor.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context) * 2),
                        borderSide: BorderSide.none,
                      ),
                      errorText: error,
                    ),
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (value) async {
                      if (value.trim().isEmpty) {
                        setState(() => error = 'Please enter a city name');
                        return;
                      }
                      setState(() {
                        isSearching = true;
                        error = null;
                      });
                      try {
                        await provider.loadWeatherForCity(value.trim());
                        if (modalContext.mounted) Navigator.pop(modalContext);
                      } catch (e) {
                        setState(() {
                          error = e.toString().replaceAll('Exception: ', '');
                          isSearching = false;
                        });
                      }
                    },
                  ),
                  SizedBox(height: responsiveSmallPadding),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSearching
                          ? null
                          : () async {
                        final value = searchController.text.trim();
                        if (value.isEmpty) {
                          setState(() => error = 'Please enter a city name');
                          return;
                        }
                        setState(() {
                          isSearching = true;
                          error = null;
                        });
                        try {
                          await provider.loadWeatherForCity(value);
                          if (modalContext.mounted) Navigator.pop(modalContext);
                        } catch (e) {
                          setState(() {
                            error = e.toString().replaceAll('Exception: ', '');
                            isSearching = false;
                          });
                        }
                      },
                      icon: isSearching
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.search_rounded),
                      label: Text(isSearching ? 'Searching...' : 'Search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: weatherColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: responsiveSmallPadding),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context) * 2),
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

  Widget _buildLoadingCard(BuildContext context) {
    final responsivePadding = AppMeasurements.getResponsivePadding(context);

    return Container(
      height: AppMeasurements.getResponsiveHeight(context, baseHeight: 220),
      margin: EdgeInsets.symmetric(horizontal: responsivePadding * 0.5),
      padding: EdgeInsets.all(responsivePadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context) * 3),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: AppMeasurements.getResponsiveIconSizeMedium(context) * 1.8,
              height: AppMeasurements.getResponsiveIconSizeMedium(context) * 1.8,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(height: responsivePadding * 0.75),
            Text(
              'Loading Weather...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WeatherProvider provider) {
    final errorColor = provider.isLocationDenied || provider.isLocationDeniedForever
        ? Theme.of(context).colorScheme.error
        : Colors.orange.shade700;
    final responsivePadding = AppMeasurements.getResponsivePadding(context);

    return Container(
      height: AppMeasurements.getResponsiveHeight(context, baseHeight: 220),
      margin: EdgeInsets.symmetric(horizontal: responsivePadding * 0.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            errorColor.withOpacity(0.3),
            errorColor.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context) * 3),
        border: Border.all(
          color: errorColor.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context) * 3),
          onTap: () => _handleErrorTap(context, provider),
          child: Padding(
            padding: EdgeInsets.all(responsivePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getErrorIcon(provider),
                  size: AppMeasurements.getResponsiveIconSizeLarge(context) * 0.7,
                  color: Colors.white,
                ),
                SizedBox(height: responsivePadding * 0.5),
                Text(
                  _getErrorTitle(provider),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                  ),
                ),
                SizedBox(height: responsivePadding * 0.25),
                Text(
                  _getErrorMessage(provider),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 13),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsivePadding * 0.5),
                Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white,
                  size: AppMeasurements.getResponsiveIconSizeMedium(context),
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
    if (provider.isLocationDeniedForever) {
      return 'Tap to open settings and enable location';
    }
    if (provider.isLocationDenied) return 'Tap to grant location access';
    if (provider.isLocationServiceDisabled) return 'Tap to enable location services';
    return provider.errorMessage ?? 'Tap to retry loading weather';
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

    // Night icons
    if (isDay == 0) {
      if (lowerCondition.contains('clear')) {
        return Icons.nightlight_round;
      } else if (lowerCondition.contains('cloudy') || lowerCondition.contains('overcast')) {
        return Icons.cloud;
      }
    }

    // Day icons
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

  Color _getWeatherColor(String condition, int isDay) {
    final lowerCondition = condition.toLowerCase();

    // Night colors
    if (isDay == 0) {
      if (lowerCondition.contains('clear')) {
        return const Color(0xFF1a237e);
      } else if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
        return const Color(0xFF263238);
      } else if (lowerCondition.contains('storm') || lowerCondition.contains('thunder')) {
        return const Color(0xFF311b92);
      } else if (lowerCondition.contains('snow') || lowerCondition.contains('sleet')) {
        return const Color(0xFF37474f);
      } else if (lowerCondition.contains('cloudy') || lowerCondition.contains('overcast')) {
        return const Color(0xFF424242);
      } else if (lowerCondition.contains('fog') || lowerCondition.contains('mist')) {
        return const Color(0xFF455a64);
      }
      return const Color(0xFF283593);
    }

    // Day colors
    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) {
      return Colors.orange.shade600;
    } else if (lowerCondition.contains('cloudy') || lowerCondition.contains('overcast')) {
      return Colors.blueGrey.shade600;
    } else if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
      return Colors.blue.shade700;
    } else if (lowerCondition.contains('storm') || lowerCondition.contains('thunder')) {
      return Colors.deepPurple.shade700;
    } else if (lowerCondition.contains('snow') || lowerCondition.contains('sleet')) {
      return Colors.lightBlue.shade600;
    } else if (lowerCondition.contains('fog') || lowerCondition.contains('mist')) {
      return Colors.grey.shade600;
    }
    return Colors.teal.shade700;
  }
}