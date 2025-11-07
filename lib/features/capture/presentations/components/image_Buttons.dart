import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

class ImageButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isEnabled;
  final VoidCallback onPressed;

  const ImageButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Reduced padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
            gradient: LinearGradient(
              colors: isPrimary
                  ? [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ]
                  : [
                Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: isPrimary
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Reduced padding
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isPrimary
                        ? [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ]
                        : [
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  size: AppMeasurements.getResponsiveIconSizeMedium(context) * 0.9, // Slightly smaller
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6), // Reduced spacing
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 13), // Smaller font
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}