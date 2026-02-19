// lib/features/home/screens/weather/weather_card/weather_card.dart
import 'package:agriguard_fyp/features/home/screens/weather/weather_card/utils/weather_card_helpers.dart';
import 'package:agriguard_fyp/features/home/screens/weather/weather_card/widgets/weather_card_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/weather_provider.dart';
import '../weather_screen/widgets/weather_details_screen.dart';
import 'widgets/weather_card_painter.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return WeatherCardWidgets.buildLoadingCard(context);
        }

        if (provider.hasError && !provider.hasData) {
          return WeatherCardWidgets.buildErrorCard(context, provider);
        }

        if (provider.hasData) {
          return _buildWeatherCard(context, provider);
        }

        return WeatherCardWidgets.buildErrorCard(context, provider);
      },
    );
  }

  Widget _buildWeatherCard(BuildContext context, WeatherProvider provider) {
    final weatherData = provider.currentWeather!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weatherColor = WeatherCardHelpers.getWeatherColor(
      weatherData.conditionText,
      weatherData.isDay,
      isDark,
    );
    final gradientColors = WeatherCardHelpers.getGradientColors(
      weatherData.conditionText,
      weatherData.isDay,
      isDark,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;
    final weatherType = WeatherCardHelpers.getWeatherType(
      weatherData.conditionText,
      weatherData.isDay,
    );

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
            // Animated weather background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WeatherCardPainter(
                      weatherType: weatherType,
                      animationValue: _animationController.value,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),

            // Text readability overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.1),
                      Colors.transparent,
                      Colors.black.withOpacity(0.15),
                    ],
                    stops: const [0.0, 0.15, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Main content
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
                      WeatherCardWidgets.buildHeader(
                        context,
                        weatherData,
                        provider,
                        weatherColor,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: WeatherCardWidgets.buildMainContent(
                          context,
                          weatherData,
                        ),
                      ),
                      const SizedBox(height: 8),
                      WeatherCardWidgets.buildBottomMetrics(weatherData),
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
}