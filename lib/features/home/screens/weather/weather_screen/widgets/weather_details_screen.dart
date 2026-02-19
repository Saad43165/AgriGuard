import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'search_bottom_sheet.dart';
import 'top_bar.dart';
import 'weather_background.dart';
import 'weather_info_grid.dart';
import '../../models/weather_model.dart';
import '../../services/weather_service.dart';
import 'current_weather_section.dart';
import 'forecast_section.dart';
import 'hourly_forecast_section.dart';

class WeatherDetailsScreen extends StatefulWidget {
  final WeatherModel weatherData;
  final List<ForecastDay>? forecastDays;
  final Color weatherColor;

  const WeatherDetailsScreen({
    super.key,
    required this.weatherData,
    this.forecastDays,
    required this.weatherColor,
  });

  @override
  State<WeatherDetailsScreen> createState() => _WeatherDetailsScreenState();
}

class _WeatherDetailsScreenState extends State<WeatherDetailsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _fadeController;
  late final AnimationController _shimmerController;
  late final Animation<double> _fadeAnimation;
  final WeatherService _weatherService = WeatherService();

  late WeatherModel _currentWeather;
  late List<ForecastDay>? _forecastDays;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true; // Keeps screen state alive when navigating away

  @override
  void initState() {
    super.initState();

    _currentWeather = widget.weatherData;
    _forecastDays = widget.forecastDays;

    // Debug log initial weather
    debugPrint('🌍 Weather Details Screen Initialized:');
    debugPrint('   Condition: ${_currentWeather.conditionText}');
    debugPrint('   Is Day: ${_currentWeather.isDay}');
    debugPrint('   Temperature: ${_currentWeather.temperature}°C');

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required when using AutomaticKeepAliveClientMixin

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weatherColor = _getWeatherColor(
      _currentWeather.conditionText,
      _currentWeather.isDay,
      isDark,
    );

    // Set status bar to always show light icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: weatherColor,
      body: Stack(
        children: [
          // Weather background with current conditions
          Positioned.fill(
            child: WeatherBackground(
              weatherColor: weatherColor,
              shimmerController: _shimmerController,
              condition: _currentWeather.conditionText,
              isDay: _currentWeather.isDay,
            ),
          ),

          // Main content
          SafeArea(
            child: _isLoading
                ? _buildLoadingIndicator()
                : RefreshIndicator(
              onRefresh: _refreshWeather,
              color: Colors.white,
              backgroundColor: weatherColor.withOpacity(0.9),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  TopBar(
                    weatherColor: weatherColor,
                    onBack: () => Navigator.pop(context),
                    onSearch: () => _showSearch(context, weatherColor),
                  ),

                  CurrentWeatherSection(
                    weatherData: _currentWeather,
                    fadeAnimation: _fadeAnimation,
                  ),

                  if (_forecastDays != null && _forecastDays!.isNotEmpty)
                    HourlyForecastSection(
                      forecastDay: _forecastDays!.first,
                      weatherColor: weatherColor,
                    ),

                  WeatherInfoGrid(weatherData: _currentWeather),

                  if (_forecastDays != null && _forecastDays!.isNotEmpty)
                    ForecastSection(
                      forecastDays: _forecastDays!,
                      weatherColor: weatherColor,
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pull-to-refresh handler
  Future<void> _refreshWeather() async {
    try {
      debugPrint('🔄 Refreshing weather data...');

      // Force refresh by passing forceRefresh: true
      // ✅ FIXED: Changed from _currentWeather.location to _currentWeather.cityName
      final forecast = await _weatherService.getWeatherByCity(
        _currentWeather.cityName,
        days: 5,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _currentWeather = forecast.current;
          _forecastDays = forecast.forecast;
        });

        debugPrint('✅ Weather refreshed successfully');
      }
    } catch (e) {
      debugPrint('❌ Refresh error: $e');

      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3.5,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Updating weather...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch(BuildContext context, Color weatherColor) {
    SearchBottomSheet.show(
      context: context,
      weatherColor: weatherColor,
      onSearch: (city) async {
        setState(() => _isLoading = true);

        try {
          // Use cached data by default (no forceRefresh)
          final forecast = await _weatherService.getWeatherByCity(city, days: 5);

          debugPrint('✅ Weather updated successfully for: $city');
          debugPrint('   New Condition: ${forecast.current.conditionText}');
          debugPrint('   New Is Day: ${forecast.current.isDay}');

          if (mounted) {
            setState(() {
              _currentWeather = forecast.current;
              _forecastDays = forecast.forecast;
              _isLoading = false;
            });

            // Reset animations
            _fadeController.reset();
            _fadeController.forward();
          }
        } catch (e) {
          debugPrint('❌ Weather fetch error: $e');

          if (mounted) {
            setState(() => _isLoading = false);
            _showErrorSnackBar(e.toString());
          }
        }
      },
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                error.replaceAll('Exception: ', ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Color _getWeatherColor(String condition, int isDay, bool isDark) {
    final c = condition.toLowerCase();

    if (isDay == 0) {
      // NIGHT
      if (c.contains('rain') || c.contains('drizzle')) {
        return const Color(0xFF1A237E);
      } else if (c.contains('storm') || c.contains('thunder')) {
        return const Color(0xFF000000);
      } else if (c.contains('snow') || c.contains('sleet')) {
        return const Color(0xFF1A237E);
      } else if (c.contains('cloud') || c.contains('overcast')) {
        return const Color(0xFF263238);
      } else if (c.contains('fog') || c.contains('mist')) {
        return const Color(0xFF37474F);
      } else {
        return const Color(0xFF0A192F); // Clear night
      }
    } else {
      // DAY
      if (c.contains('sunny') || c.contains('clear')) {
        return const Color(0xFF1E88E5);
      } else if (c.contains('rain') || c.contains('drizzle')) {
        return const Color(0xFF455A64);
      } else if (c.contains('storm') || c.contains('thunder')) {
        return const Color(0xFF263238);
      } else if (c.contains('snow') || c.contains('sleet')) {
        return const Color(0xFF64B5F6);
      } else if (c.contains('overcast')) {
        return const Color(0xFF546E7A); // Specific for overcast
      } else if (c.contains('cloud')) {
        return const Color(0xFF5C6BC0); // Partly cloudy
      } else if (c.contains('fog') || c.contains('mist')) {
        return const Color(0xFF78909C);
      }

      return const Color(0xFF1E88E5); // Default sunny
    }
  }
}