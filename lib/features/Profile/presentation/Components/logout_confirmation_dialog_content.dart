import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart';

class LogoutConfirmationDialogContent extends StatelessWidget {
  final VoidCallback onConfirm;

  const LogoutConfirmationDialogContent({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
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
            'Confirm Logout',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
            ),
          ),
          SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
          Text(
            'Are you sure you want to log out?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor.withOpacity(0.9),
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
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
                  foregroundColor: textColor,
                  side: BorderSide(color: textColor.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
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