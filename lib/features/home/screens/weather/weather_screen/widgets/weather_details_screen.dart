import 'package:agriguard_fyp/features/home/screens/weather/weather_screen/widgets/search_bottom_sheet.dart';
import 'package:agriguard_fyp/features/home/screens/weather/weather_screen/widgets/top_bar.dart';
import 'package:agriguard_fyp/features/home/screens/weather/weather_screen/widgets/weather_background.dart';
import 'package:agriguard_fyp/features/home/screens/weather/weather_screen/widgets/weather_info_grid.dart';
import 'package:flutter/material.dart';
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
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _shimmerController;
  late final Animation<double> _fadeAnimation;

  // Local state to hold updated weather data
  late WeatherModel _currentWeather;
  late List<ForecastDay>? _forecastDays;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize with passed data
    _currentWeather = widget.weatherData;
    _forecastDays = widget.forecastDays;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weatherColor = _getWeatherColor(
      _currentWeather.conditionText,
      _currentWeather.isDay,
      isDark,
    );

    return Scaffold(
      body: Stack(
        children: [
          WeatherBackground(
            weatherColor: weatherColor,
            shimmerController: _shimmerController,
          ),
          SafeArea(
            child: _isLoading
                ? _buildLoadingIndicator()
                : CustomScrollView(
              physics: const BouncingScrollPhysics(),
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

                // Hourly Forecast Section
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
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 3,
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
          // Import the service to load weather directly
          final weatherService = WeatherService();
          final forecast = await weatherService.getWeatherByCity(city, days: 5);

          if (mounted) {
            setState(() {
              _currentWeather = forecast.current;
              _forecastDays = forecast.forecast;
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);

            // Show error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.toString().replaceAll('Exception: ', ''),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          // Re-throw to let the bottom sheet handle it
          rethrow;
        }
      },
    );
  }

  Color _getWeatherColor(String condition, int isDay, bool isDark) {
    final c = condition.toLowerCase();

    if (isDay == 0) {
      if (c.contains('clear')) {
        return isDark ? const Color(0xFF3949AB) : const Color(0xFF1a237e);
      } else if (c.contains('rain') || c.contains('drizzle')) {
        return isDark ? const Color(0xFF455A64) : const Color(0xFF263238);
      } else if (c.contains('storm') || c.contains('thunder')) {
        return isDark ? const Color(0xFF512DA8) : const Color(0xFF311b92);
      } else if (c.contains('snow') || c.contains('sleet')) {
        return isDark ? const Color(0xFF546E7A) : const Color(0xFF37474f);
      } else if (c.contains('cloudy') || c.contains('overcast')) {
        return isDark ? const Color(0xFF616161) : const Color(0xFF424242);
      }
      return isDark ? const Color(0xFF5C6BC0) : const Color(0xFF283593);
    }

    if (c.contains('sunny') || c.contains('clear')) {
      return isDark ? const Color(0xFFFF9800) : const Color(0xFFEF6C00);
    } else if (c.contains('cloudy') || c.contains('overcast')) {
      return isDark ? const Color(0xFF78909C) : const Color(0xFF546E7A);
    } else if (c.contains('rain') || c.contains('drizzle')) {
      return isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    } else if (c.contains('storm') || c.contains('thunder')) {
      return isDark ? const Color(0xFF7E57C2) : const Color(0xFF512DA8);
    } else if (c.contains('snow') || c.contains('sleet')) {
      return isDark ? const Color(0xFF4FC3F7) : const Color(0xFF0288D1);
    }
    return isDark ? const Color(0xFF26A69A) : const Color(0xFF00897B);
  }
}