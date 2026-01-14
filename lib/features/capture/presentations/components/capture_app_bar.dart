import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';

class CaptureAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentStep;
  final bool isProcessing;
  final VoidCallback? onBackPressed;
  final VoidCallback? onInfoPressed;
  final String appBarTitle;

  const CaptureAppBar({
    super.key,
    required this.currentStep,
    required this.isProcessing,
    required this.appBarTitle,
    this.onBackPressed,
    this.onInfoPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button on LEFT SIDE
            if (currentStep > 0 && !isProcessing)
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
                    onTap: onBackPressed,
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
              )
            else
              Container(width: 50), // Spacer to maintain layout

            // Title in Center with Gradient
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ).createShader(bounds),
                child: Text(
                  _getShortTitle(appBarTitle),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 24),
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Info Button or Empty Spacer on RIGHT SIDE
            if (currentStep == 0 && !isProcessing)
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
                    onTap: onInfoPressed,
                    child: Padding(
                      padding: EdgeInsets.all(padding * 0.5),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: AppMeasurements.getResponsiveIconSizeMedium(context),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(width: 50), // Spacer to maintain layout
          ],
        ),
      ),
    );
  }

  // Helper method to shorten long titles
  String _getShortTitle(String originalTitle) {
    if (originalTitle.contains('Choose Analysis Method')) {
      return 'Analysis Method';
    }
    if (originalTitle.contains('Advanced AI Analysis')) {
      return 'AI Analysis';
    }
    if (originalTitle.length > 20) {
      return '${originalTitle.substring(0, 17)}...';
    }
    return originalTitle;
  }
}