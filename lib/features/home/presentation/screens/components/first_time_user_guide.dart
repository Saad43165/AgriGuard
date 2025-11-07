import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/glass_card.dart';

class FirstTimeUserGuide extends StatelessWidget {
  const FirstTimeUserGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Start Guide',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CompactGuideStep(
              icon: Icons.camera_alt_rounded,
              title: 'Scan Plant',
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _CompactGuideStep(
              icon: Icons.analytics_rounded,
              title: 'Get AI Diagnosis',
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 8),
            _CompactGuideStep(
              icon: Icons.medical_services_rounded,
              title: 'View Treatment',
              color: Theme.of(context).colorScheme.tertiary ??
                  Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactGuideStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _CompactGuideStep({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: AppMeasurements.getResponsiveFontSize(
                context,
                baseSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}