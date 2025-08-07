import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../Profile/presentation/Components/glass_card.dart';
import 'section_header.dart';

class RecommendationsCard extends StatelessWidget {
  final List<String> recommendations;

  const RecommendationsCard({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Treatment Recommendations',
          icon: Icons.medical_services_rounded,
        ),
        const SizedBox(height: AppMeasurements.smallPadding),
        GlassCard(
          child: Column(
            children: recommendations.asMap().entries.map((entry) {
              final isLast = entry.key == recommendations.length - 1;
              return Container(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                          size: AppMeasurements.getResponsiveIconSizeSmall(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}