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
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isPrimary
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
                Theme.of(context).colorScheme.secondary.withOpacity(0.15),
              ],
            )
                : LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
            border: Border.all(
              color: isPrimary
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isPrimary
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isPrimary
                      ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  )
                      : null,
                  color: isPrimary
                      ? null
                      : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  boxShadow: isPrimary
                      ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: AppMeasurements.getResponsiveIconSizeMedium(context) * 0.8,
                  color: isPrimary
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 8),

              // Label
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 13),
                  letterSpacing: 0.2,
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