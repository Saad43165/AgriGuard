import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_strings.dart';

/// A button widget for triggering the password reset action.
class ActionButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.isLoading,
    required this.onPressed, required String label, required IconData icon, required String loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        onTap: isLoading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppMeasurements.defaultPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: isLoading
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: AppMeasurements.iconSizeMedium,
                height: AppMeasurements.iconSizeMedium,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: AppMeasurements.smallPadding),
              Text(
                'Sending...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                ),
              ),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.send_rounded,
                size: AppMeasurements.iconSizeMedium,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(width: AppMeasurements.smallPadding),
              Text(
                AppStrings.sendResetLink,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}