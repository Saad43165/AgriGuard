// lib/features/home/screens/weather/weather_card/weather_card_widgets.dart
import 'package:flutter/material.dart';
import '../../provider/weather_provider.dart';
import '../../models/weather_model.dart';
import '../utils/weather_card_helpers.dart';
import 'weather_card_dialogs.dart';

class WeatherCardWidgets {
  static Widget buildHeader(
      BuildContext context,
      WeatherModel weatherData,
      WeatherProvider provider,
      Color weatherColor,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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
                      WeatherCardHelpers.getLocationTime(provider),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
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
        Row(
          children: [
            _buildActionButton(
              context,
              Icons.search_rounded,
                  () => WeatherCardDialogs.showSearchDialog(
                context,
                provider,
                weatherColor,
              ),
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
    );
  }

  static Widget buildMainContent(BuildContext context, WeatherModel weatherData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                WeatherCardHelpers.getWeatherIcon(
                  weatherData.conditionText,
                  weatherData.isDay,
                ),
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
    );
  }

  static Widget buildBottomMetrics(WeatherModel weatherData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(Icons.water_drop_rounded, '${weatherData.humidity}%'),
          _buildDivider(),
          _buildMetric(Icons.air_rounded, weatherData.windSpeed.toStringAsFixed(0)),
          _buildDivider(),
          _buildMetric(Icons.wb_sunny_rounded, weatherData.uvIndex.toStringAsFixed(1)),
        ],
      ),
    );
  }

  static Widget buildLoadingCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (screenWidth * 0.025).clamp(8.0, 12.0);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: 175,
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [primaryColor.withValues(alpha: 0.2), primaryColor.withValues(alpha: 0.1)]
              : [primaryColor.withValues(alpha: 0.15), primaryColor.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.2), width: 1.5),
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

  static Widget buildErrorCard(BuildContext context, WeatherProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = provider.isLocationDenied || provider.isLocationDeniedForever
        ? Theme.of(context).colorScheme.error
        : (isDark ? Colors.orange.shade400 : Colors.orange.shade700);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (screenWidth * 0.025).clamp(8.0, 12.0);

    return Container(
      height: 175,
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [errorColor.withValues(alpha: 0.2), errorColor.withValues(alpha: 0.1)]
              : [errorColor.withValues(alpha: 0.15), errorColor.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: errorColor.withValues(alpha: isDark ? 0.4 : 0.3), width: 1.5),
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
                    color: errorColor.withValues(alpha: 0.2),
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
                    color: isDark ? errorColor.withValues(alpha: 0.8) : errorColor.withValues(alpha: 0.9),
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

  // Private helper methods
  static Widget _buildActionButton(
      BuildContext context,
      IconData? icon,
      VoidCallback? onTap, {
        bool isLoading = false,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
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

  static Widget _buildMetric(IconData icon, String value) {
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

  static Widget _buildDivider() {
    return Container(
      width: 1,
      height: 14,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  static IconData _getErrorIcon(WeatherProvider provider) {
    if (provider.isLocationDenied || provider.isLocationDeniedForever) {
      return Icons.location_off_rounded;
    } else if (provider.isLocationServiceDisabled) {
      return Icons.location_disabled_rounded;
    }
    return Icons.cloud_off_rounded;
  }

  static String _getErrorTitle(WeatherProvider provider) {
    if (provider.isLocationDeniedForever) return 'Permission Required';
    if (provider.isLocationDenied) return 'Location Required';
    if (provider.isLocationServiceDisabled) return 'Location Services Off';
    return 'Weather Unavailable';
  }

  static String _getErrorMessage(WeatherProvider provider) {
    if (provider.isLocationDeniedForever) return 'Tap to open settings';
    if (provider.isLocationDenied) return 'Tap to grant access';
    if (provider.isLocationServiceDisabled) return 'Tap to enable services';
    return provider.errorMessage ?? 'Tap to retry';
  }

  static void _handleErrorTap(BuildContext context, WeatherProvider provider) {
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
}