// lib/features/ResultScreen/presentation/widgets/results/section_card.dart
import 'package:flutter/material.dart';
import 'package:agriguard_fyp/core/constants/app_measurements.dart';

class SectionCard extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;

  const SectionCard({
    super.key,
    required this.theme,
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        AppMeasurements.getResponsivePadding(context),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  AppMeasurements.getResponsiveSmallPadding(context) * 0.6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: AppMeasurements.getResponsiveIconSizeSmall(context),
                  color: color,
                ),
              ),
              SizedBox(
                width: AppMeasurements.getResponsiveSmallPadding(context),
              ),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(
            height: AppMeasurements.getResponsiveSmallPadding(context),
          ),
          ...items.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: AppMeasurements.getResponsiveSmallPadding(context) * 0.5,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(
                    width: AppMeasurements.getResponsiveSmallPadding(context),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}