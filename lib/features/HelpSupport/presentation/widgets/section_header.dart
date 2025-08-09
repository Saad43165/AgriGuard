import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

/// A reusable section header with an icon and title.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final double itemSpacing;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(itemSpacing),
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
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
          ),
        ),
        SizedBox(width: itemSpacing),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
          ),
        ),
      ],
    );
  }
}