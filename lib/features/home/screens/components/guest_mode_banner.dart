import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/Login_Screen/services/guest_service.dart';

/// Banner widget to display guest mode information
class GuestModeBanner extends StatelessWidget {
  final GuestService guestService;

  const GuestModeBanner({
    super.key,
    required this.guestService,
  });

  @override
  Widget build(BuildContext context) {
    if (!guestService.isGuestMode) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppMeasurements.getResponsivePadding(context) * 0.4,
        vertical: AppMeasurements.getResponsiveSmallPadding(context),
      ),
      padding: EdgeInsets.all(
        AppMeasurements.getResponsiveSmallPadding(context),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.white,
            size: AppMeasurements.getResponsiveIconSizeSmall(context),
          ),
          SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Guest Mode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${guestService.remainingScans} scans remaining',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                    (route) => false,
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: EdgeInsets.symmetric(
                horizontal: AppMeasurements.getResponsiveSmallPadding(context),
                vertical: AppMeasurements.getResponsiveSmallPadding(context) * 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppMeasurements.getResponsiveBorderRadius(context) * 0.6,
                ),
              ),
            ),
            child: Text(
              'Sign In',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact scan counter widget for capture screen
class GuestScanCounter extends StatelessWidget {
  final GuestService guestService;

  const GuestScanCounter({
    super.key,
    required this.guestService,
  });

  @override
  Widget build(BuildContext context) {
    if (!guestService.isGuestMode) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppMeasurements.getResponsiveSmallPadding(context),
        vertical: AppMeasurements.getResponsiveSmallPadding(context) * 0.5,
      ),
      decoration: BoxDecoration(
        color: guestService.remainingScans <= 2
            ? Colors.red.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        border: Border.all(
          color: guestService.remainingScans <= 2
              ? Colors.red.shade400
              : Colors.orange.shade400,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: AppMeasurements.getResponsiveIconSizeSmall(context) * 0.8,
            color: guestService.remainingScans <= 2
                ? Colors.red.shade700
                : Colors.orange.shade700,
          ),
          SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context) * 0.5),
          Text(
            '${guestService.remainingScans} scans left',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: guestService.remainingScans <= 2
                  ? Colors.red.shade700
                  : Colors.orange.shade700,
              fontWeight: FontWeight.w600,
              fontSize: AppMeasurements.getResponsiveFontSize(
                context,
                baseSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}