import 'package:flutter/material.dart';

class OnboardingTopBar extends StatelessWidget {
  final VoidCallback onSkip;
  final int currentPage;
  final int totalPages;

  const OnboardingTopBar({
    super.key,
    required this.onSkip,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              _buildLogo(theme, colorScheme),

              // Skip button (only show if not on last page)
              if (currentPage < totalPages - 1)
                _buildSkipButton(theme, colorScheme),
            ],
          ),

          // Progress bar
          const SizedBox(height: 16),
          _buildProgressBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildLogo(ThemeData theme, ColorScheme colorScheme) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: [colorScheme.primary, colorScheme.secondary],
      ).createShader(bounds),
      child: Text(
        'AgriGuard',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSkipButton(ThemeData theme, ColorScheme colorScheme) {
    return TextButton(
      onPressed: onSkip,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        'Skip',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    return LinearProgressIndicator(
      value: (currentPage + 1) / totalPages,
      backgroundColor: colorScheme.primary.withOpacity(0.2),
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(10),
      minHeight: 4,
    );
  }
}