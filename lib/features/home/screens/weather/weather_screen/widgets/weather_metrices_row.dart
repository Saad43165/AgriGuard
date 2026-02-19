import 'package:flutter/material.dart';

class WeatherMetricsRow extends StatelessWidget {
  final int humidity;
  final double windSpeed;
  final double uvIndex;
  final Color weatherColor;

  const WeatherMetricsRow({
    super.key,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.weatherColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(
            context,
            Icons.water_drop_rounded,
            'Humidity',
            '$humidity%',
            Colors.blue,
            isDark,
          ),
          _buildDivider(context, isDark),
          _buildMetric(
            context,
            Icons.air_rounded,
            'Wind',
            '${windSpeed.toStringAsFixed(1)}',
            Colors.cyan,
            isDark,
          ),
          _buildDivider(context, isDark),
          _buildMetric(
            context,
            Icons.wb_sunny_rounded,
            'UV',
            uvIndex.toStringAsFixed(1),
            Colors.orange,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      Color color,
      bool isDark,
      ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(isDark ? 0.15 : 0.2),
              color.withOpacity(isDark ? 0.08 : 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isDark ? Colors.white : color,              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.6),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context, bool isDark) {
    return Container(
      width: 1,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}