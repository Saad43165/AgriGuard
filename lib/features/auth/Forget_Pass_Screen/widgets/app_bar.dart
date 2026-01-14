// features/auth/forgot_password/weather_screen/support_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_measurements.dart';

/// A custom AppBar for the ForgotPasswordScreen.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.onBackPressed,
  });

  // Shared gradient colors
  static List<Color> _gradientColors(BuildContext context) => [
    Theme.of(context).colorScheme.primary,
    Theme.of(context).colorScheme.secondary,
  ];

  @override
  Widget build(BuildContext context) {
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: _gradientColors(context),
        ).createShader(bounds),
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: AppMeasurements.getResponsiveFontSize(
              context,
              baseSize: 24,
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: smallPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: () {
                HapticFeedback.lightImpact();
                onBackPressed();
              },
              child: Padding(
                padding: EdgeInsets.all(smallPadding),
                child: SizedBox(
                  width: 18,  // Fixed icon area
                  height: 18, // Fixed icon area
                  child: Center(
                    child: Transform.scale(
                      scale: 1.3, // Enlarge icon by 30%
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: _gradientColors(context),
                        ).createShader(bounds),
                        child: Icon(
                          AppIcons.back,
                          size: 20, // Base size (larger than container)
                          color: Colors.white, // Required for ShaderMask
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}