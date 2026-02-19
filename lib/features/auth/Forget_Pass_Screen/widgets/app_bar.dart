import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_measurements.dart';

/// A custom AppBar for the ForgotPasswordScreen.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBackPressed;
  final double topPadding;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.onBackPressed,
    this.topPadding = 0,
  });

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
      centerTitle: true, // ✅ Center the title
      leading: Container(
        margin: EdgeInsets.only(left: smallPadding),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
                Theme.of(context).colorScheme.secondary.withOpacity(0.15),
              ],
            ),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
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
              child: Center(
                widthFactor: 30,
                heightFactor: 50,
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: _gradientColors(context),
                  ).createShader(bounds),
                  child: Icon(
                    AppIcons.back,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: _gradientColors(context),
        ).createShader(bounds),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: AppMeasurements.getResponsiveFontSize(
              context,
              baseSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}