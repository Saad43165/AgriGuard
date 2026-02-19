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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x4D000000), Color(0x33000000)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x59FFFFFF), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${forecastDays.length}-Day Forecast',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: forecastDays.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, index) => ForecastCard(
              day: forecastDays[index],
              index: index,
              onTap: () => _navigateToDayDetail(ctx, forecastDays[index], weatherColor),
            ),
          ),
          const SizedBox(height: 16),
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