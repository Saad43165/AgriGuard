// lib/features/home/screens/weather/weather_screen/forecast_section.dart
import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import 'forecast_card.dart';

class ForecastSection extends StatelessWidget {
  final List<ForecastDay> forecastDays;

  const ForecastSection({
    super.key,
    required this.forecastDays,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(left: 10,top: 10),
            child: Row(
              children: const [
                _IconChip(icon: Icons.calendar_today_rounded, size: 20),
                SizedBox(width: 12),
                Text(
                  '3-Day Forecast',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Forecast cards – one per day
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: forecastDays.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) => ForecastCard(
              day: forecastDays[index],
              index: index,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final double size;

  const _IconChip({required this.icon, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}