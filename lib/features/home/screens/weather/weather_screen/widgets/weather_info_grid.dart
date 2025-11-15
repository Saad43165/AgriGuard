// lib/widgets/weather_info_grid.dart
import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../items/icon_item.dart';

class WeatherInfoGrid extends StatelessWidget {
  final WeatherModel weatherData;

  const WeatherInfoGrid({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _row(
                left: InfoItem(
                  icon: Icons.water_drop_rounded,
                  label: 'Humidity',
                  value: '${weatherData.humidity}%',
                ),
                right: InfoItem(
                  icon: Icons.air_rounded,
                  label: 'Wind Speed',
                  value: '${weatherData.windSpeed.toStringAsFixed(1)} km/h',
                ),
              ),
              const Divider(),
              _row(
                left: InfoItem(
                  icon: Icons.wb_sunny_rounded,
                  label: 'UV Index',
                  value: weatherData.uvIndex.toStringAsFixed(1),
                ),
                right: InfoItem(
                  icon: Icons.speed_rounded,
                  label: 'Pressure',
                  value: '${weatherData.pressure.toStringAsFixed(0)} mb',
                ),
              ),
              const Divider(),
              _row(
                left: InfoItem(
                  icon: Icons.visibility_rounded,
                  label: 'Visibility',
                  value: '${weatherData.visibilityKm.toStringAsFixed(1)} km',
                ),
                right: InfoItem(
                  icon: Icons.cloud_rounded,
                  label: 'Cloud Cover',
                  value: '${weatherData.cloudCover}%',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row({required Widget left, required Widget right}) => Row(
    children: [
      Expanded(child: left),
      Container(width: 1.5, height: 50, color: Colors.white.withOpacity(0.3)),
      Expanded(child: right),
    ],
  );

  Widget get _Divider => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Divider(color: Colors.white30, height: 1, thickness: 1.5),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white.withOpacity(0.2),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}