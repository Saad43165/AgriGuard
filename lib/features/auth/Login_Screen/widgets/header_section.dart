import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_measurements.dart';

/// A header widget with logo and title.
class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppMeasurements.smallPadding),
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
            AppIcons.logo,
            size: AppMeasurements.iconSizeLarge,
            color: Theme.of(context).colorScheme.primary,
            semanticLabel: 'AgriGuard Logo',
          ),
        ),
        const SizedBox(height: AppMeasurements.smallPadding),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            'AgriGuard',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 32),
            ),
            textAlign: TextAlign.center,
            semanticsLabel: 'AgriGuard',
          ),
        ),
        const SizedBox(height: AppMeasurements.smallPadding),
        Text(
          'Protecting Your Crops',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}