import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';

class ScanButton extends StatelessWidget {
  final Animation<double> pulseAnimation;

  const ScanButton({super.key, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pushNamed(context, '/ResultScreen');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: AppMeasurements.getResponsiveIconSizeSmall(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Scan Plant',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}