import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/constants/app_routes.dart';
import 'glass_card.dart';

class LogoutDialogContent extends StatelessWidget {
  const LogoutDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_rounded,
            color: Theme.of(context).colorScheme.error,
            size: AppMeasurements.getResponsiveIconSizeLarge(context),
          ),
          SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
          Text(
            'Logout',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
          Text(
            'Are you sure you want to log out?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context) * 1.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}