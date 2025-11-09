import 'package:flutter/material.dart';

import '../../../core/constants/app_measurements.dart';

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
    final isLargeScreen = AppMeasurements.isLargeScreen(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppMeasurements.getResponsivePadding(context),
        vertical: AppMeasurements.smallPadding,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo with enhanced animation
              _buildLogo(context, theme, colorScheme, isLargeScreen),

              // Skip button (only show if not on last page)
              if (currentPage < totalPages - 1)
                _buildSkipButton(context, theme, colorScheme),
            ],
          ),

          // Progress bar with smooth animation
          SizedBox(height: AppMeasurements.smallPadding),
          _buildProgressBar(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context, ThemeData theme, ColorScheme colorScheme, bool isLargeScreen) {
    return Row(
      children: [
        // Optional: Add an icon/emoji for better branding
        Container(
          padding: EdgeInsets.all(AppMeasurements.extraSmallPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.2),
                colorScheme.secondary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context),
            ),
          ),
          child: Icon(
            Icons.eco_rounded,
            color: colorScheme.primary,
            size: AppMeasurements.getResponsiveIconSizeMedium(context),
          ),
        ),
        SizedBox(width: AppMeasurements.extraSmallPadding),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'AgriGuard',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontSize: AppMeasurements.getResponsiveFontSize(
                context,
                baseSize: isLargeScreen ? 26 : 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSkip,
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppMeasurements.getResponsiveSmallPadding(context),
            vertical: AppMeasurements.getResponsiveExtraSmallPadding(context),
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Skip',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 15,
                  ),
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                color: colorScheme.primary,
                size: AppMeasurements.getResponsiveIconSizeSmall(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      tween: Tween<double>(
        begin: currentPage / totalPages,
        end: (currentPage + 1) / totalPages,
      ),
      builder: (context, value, _) {
        return Stack(
          children: [
            // Background
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Animated progress
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}