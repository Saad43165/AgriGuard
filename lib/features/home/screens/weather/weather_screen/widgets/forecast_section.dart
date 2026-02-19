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
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
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
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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