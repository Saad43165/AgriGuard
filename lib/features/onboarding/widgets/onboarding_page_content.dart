import 'package:flutter/material.dart';
import '../models/onboarding_data.dart';

class OnboardingPageContent extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPageContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon with gradient effects
          _buildAnimatedIcon(colorScheme),

          const SizedBox(height: 48),

          // Title with fade-in animation capability
          _buildTitle(theme, colorScheme),

          const SizedBox(height: 16),

          // Description with readability optimization
          _buildDescription(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(ColorScheme colorScheme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow effect
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colorScheme.primary.withOpacity(0.2),
                colorScheme.primary.withOpacity(0.0),
              ],
              stops: const [0.1, 1.0],
            ),
          ),
        ),

        // Middle glow layer
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colorScheme.secondary.withOpacity(0.1),
                colorScheme.secondary.withOpacity(0.0),
              ],
              stops: const [0.1, 1.0],
            ),
          ),
        ),

        // Icon container with shadow
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              data.icon,
              style: const TextStyle(fontSize: 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme, ColorScheme colorScheme) {
    return Text(
      data.title,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
    );
  }

  Widget _buildDescription(ThemeData theme, ColorScheme colorScheme) {
    return Text(
      data.description,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface.withOpacity(0.7),
        height: 1.6,
        fontSize: 16,
        letterSpacing: 0.2,
      ),
      textAlign: TextAlign.center,
    );
  }
}