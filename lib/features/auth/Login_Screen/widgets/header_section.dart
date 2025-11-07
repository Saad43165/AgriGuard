import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_measurements.dart';

/// A polished header widget with logo and title.
class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Logo with gradient and glow effect
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect layers
            Container(
              width: AppMeasurements.iconSizeLarge + 40,
              height: AppMeasurements.iconSizeLarge + 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.2),
                    colorScheme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            Container(
              width: AppMeasurements.iconSizeLarge + 20,
              height: AppMeasurements.iconSizeLarge + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.secondary.withOpacity(0.3),
                    colorScheme.secondary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            // Main icon with gradient
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ).createShader(bounds),
              child: Icon(
                AppIcons.logo,
                size: AppMeasurements.iconSizeLarge,
                semanticLabel: 'AgriGuard Logo',
              ),
            ),
          ],
        ),

         SizedBox(height: AppMeasurements.mediumPadding),

        // App name with gradient effect
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            'AgriGuard',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: AppMeasurements.getResponsiveFontSize(
                context,
                baseSize: 36,
              ),
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            semanticsLabel: 'AgriGuard',
          ),
        ),

        const SizedBox(height: AppMeasurements.extraSmallPadding),

        // Subtitle with better styling
        Text(
          'Recover your account',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w400,
            fontSize: AppMeasurements.getResponsiveFontSize(
              context,
              baseSize: 15,
            ),
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}