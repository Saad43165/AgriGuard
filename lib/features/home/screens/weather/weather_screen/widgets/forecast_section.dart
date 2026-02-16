import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import 'forecast_card.dart';
import 'day_detail_screen.dart';

class ForecastSection extends StatelessWidget {
  final List<ForecastDay> forecastDays;
  final Color weatherColor;

  const ForecastSection({
    super.key,
    required this.forecastDays,
    required this.weatherColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 16, 26, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${forecastDays.length}-Day Forecast',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: forecastDays.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) => ForecastCard(
              day: forecastDays[index],
              index: index,
              onTap: () => _navigateToDayDetail(ctx, forecastDays[index], weatherColor),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDayDetail(BuildContext context, ForecastDay day, Color weatherColor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailScreen(
          forecastDay: day,
          weatherColor: weatherColor,
        ),
      ),
    );
  }
}