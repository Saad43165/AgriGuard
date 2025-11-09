// features/auth/Registration_screen/widgets/register_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';

class RegisterAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RegisterAppBar({super.key});

  // Gradient used for both title and back icon
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
          'Create Account',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
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
                Navigator.pop(context);
              },
              child: Padding(
                padding: EdgeInsets.all(smallPadding), // Keep original padding
                child: SizedBox(
                  width: 18,   // Fixed icon area width
                  height: 18,  // Fixed icon area height
                  child: Center(
                    child: Transform.scale(
                      scale: 1.3, // Enlarge icon by 30% (adjust as needed)
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: _gradientColors(context),
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20, // Base size (smaller than container)
                          color: Colors.white, // Required for gradient
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}