// lib/screens/weather_details_screen.dart
import 'package:agriguard_fyp/features/home/screens/weather/weather_screen/widgets/search_bottom_sheet.dart';
import 'package:agriguard_fyp/features/home/screens/weather/weather_screen/widgets/top_bar.dart';
import 'package:agriguard_fyp/features/home/screens/weather/weather_screen/widgets/weather_background.dart';
import 'package:agriguard_fyp/features/home/screens/weather/weather_screen/widgets/weather_info_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weather_model.dart';
import '../../provider/weather_provider.dart';
import 'current_weather_section.dart';
import 'forecast_section.dart';


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

  @override
  void initState() {
    super.initState();
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
    final weatherColor = _getWeatherColor(
      widget.weatherData.conditionText,
      widget.weatherData.isDay,
    );

    return Scaffold(
      body: Stack(
        children: [
          WeatherBackground(
            weatherColor: weatherColor,
            shimmerController: _shimmerController,
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                TopBar(
                  weatherColor: weatherColor,
                  onBack: () => Navigator.pop(context),
                  onSearch: () => SearchBottomSheet.show(
                    context: context,
                    weatherColor: weatherColor,
                    onSearch: (city) async {
                      final provider = Provider.of<WeatherProvider>(context, listen: false);
                      await provider.loadWeatherForCity(city);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
                CurrentWeatherSection(
                  weatherData: widget.weatherData,
                  fadeAnimation: _fadeAnimation,
                ),
                WeatherInfoGrid(weatherData: widget.weatherData),
                if (widget.forecastDays != null && widget.forecastDays!.isNotEmpty)
                  ForecastSection(forecastDays: widget.forecastDays!),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Helper methods – kept here because they are used only by this screen
  // -----------------------------------------------------------------
  IconData _getWeatherIcon(String condition, int isDay) {
    final c = condition.toLowerCase();
    if (isDay == 0) {
      if (c.contains('clear')) return Icons.nightlight_round;
      if (c.contains('cloudy') || c.contains('overcast')) return Icons.cloud;
    }
    if (c.contains('sunny') || c.contains('clear')) return Icons.wb_sunny_rounded;
    if (c.contains('cloudy') || c.contains('overcast')) return Icons.cloud_rounded;
    if (c.contains('rain') || c.contains('drizzle')) return Icons.water_drop_rounded;
    if (c.contains('storm') || c.contains('thunder')) return Icons.thunderstorm_rounded;
    if (c.contains('snow') || c.contains('sleet')) return Icons.ac_unit_rounded;
    if (c.contains('fog') || c.contains('mist')) return Icons.foggy;
    return Icons.wb_cloudy_rounded;
  }

  Color _getWeatherColor(String condition, int isDay) {
    final c = condition.toLowerCase();
    if (isDay == 0) {
      if (c.contains('clear')) return const Color(0xFF1a237e);
      if (c.contains('rain') || c.contains('drizzle')) return const Color(0xFF263238);
      if (c.contains('storm') || c.contains('thunder')) return const Color(0xFF311b92);
      if (c.contains('snow') || c.contains('sleet')) return const Color(0xFF37474f);
      if (c.contains('cloudy') || c.contains('overcast')) return const Color(0xFF424242);
      if (c.contains('fog') || c.contains('mist')) return const Color(0xFF455a64);
      return const Color(0xFF283593);
    }
    if (c.contains('sunny') || c.contains('clear')) return Colors.orange.shade600;
    if (c.contains('cloudy') || c.contains('overcast')) return Colors.blueGrey.shade600;
    if (c.contains('rain') || c.contains('drizzle')) return Colors.blue.shade700;
    if (c.contains('storm') || c.contains('thunder')) return Colors.deepPurple.shade700;
    if (c.contains('snow') || c.contains('sleet')) return Colors.lightBlue.shade600;
    if (c.contains('fog') || c.contains('mist')) return Colors.grey.shade600;
    return Colors.teal.shade700;
  }
}