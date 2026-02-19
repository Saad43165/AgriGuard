import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';

class RegisterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentStep;
  final VoidCallback onBackPressed;

  const RegisterAppBar({
    super.key,
    required this.currentStep,
    required this.onBackPressed,
  });

  static List<Color> _gradientColors(BuildContext context) => [
    Theme.of(context).colorScheme.primary,
    Theme.of(context).colorScheme.secondary,
  ];

  String _getStepTitle() {
    switch (currentStep) {
      case 0:
        return 'Basic Info';
      case 1:
        return 'Farm Details';
      case 2:
        return 'Security';
      default:
        return 'Create Account';
    }
  }

  @override
  Widget build(BuildContext context) {
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
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
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: _gradientColors(context),
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      title: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: _gradientColors(context),
            ).createShader(bounds),
            child: Text(
              _getStepTitle(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Step ${currentStep + 1} of 3',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}