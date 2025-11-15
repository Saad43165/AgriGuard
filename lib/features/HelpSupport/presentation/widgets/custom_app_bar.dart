// lib/core/weather_screen/custom_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart'; // Make sure this exists

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final double elevation;
  final double topPadding;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.elevation = 0,
    this.topPadding = 8.0,
  });

  // NEW: Helper to go back to Profile screen
  void _goBackToProfile(BuildContext context) {
    HapticFeedback.lightImpact();

    // If custom callback is provided, use it
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }

    // Otherwise: pop until we reach the Profile screen
    Navigator.popUntil(context, (route) {
      return route.settings.name == AppRoutes.profile;
    });

    // If Profile is not in stack, fallback to Home
    if (ModalRoute.of(context)?.settings.name != AppRoutes.profile) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.profile,
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: elevation,
        centerTitle: true,
        title: Semantics(
          label: 'App bar with back button',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ).createShader(bounds),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 26),
                    color: Colors.white, // ShaderMask needs white base
                  ),
                ),
              ),

              // Back Button
              if (showBackButton)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
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
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _goBackToProfile(context), // Fixed navigation
                      child: Padding(
                        padding: EdgeInsets.all(padding * 0.5),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: AppMeasurements.getResponsiveIconSizeMedium(context),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}