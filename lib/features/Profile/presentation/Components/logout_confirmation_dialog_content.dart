import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';
// ← ADD THIS IMPORT

class LogoutConfirmationDialogContent extends StatelessWidget {
  final VoidCallback onConfirm;

  const LogoutConfirmationDialogContent({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(
        AppMeasurements.defaultPadding,
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppMeasurements.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context) * 2,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.error.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Warning Icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.error.withOpacity(0.15),
                  Theme.of(context).colorScheme.error.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.logout_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 42,
            ),
          ),

          SizedBox(height: AppMeasurements.defaultPadding),

          // Title
          Text(
            'Logout Confirmation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: AppMeasurements.getResponsiveFontSize(
                context,
                baseSize: 22,
              ),
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),

          // Description
          Container(
            padding: EdgeInsets.all(
              AppMeasurements.getResponsiveSmallPadding(context),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.error.withOpacity(0.05),
                  Theme.of(context).colorScheme.error.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(
                AppMeasurements.getResponsiveBorderRadius(context),
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Important Notice',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: AppMeasurements.getResponsiveFontSize(
                          context,
                          baseSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'You will need to log in again to access your account, scan history, and all saved data.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 14,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: AppMeasurements.defaultPadding),

          // Buttons
          Row(
            children: [
              // Cancel Button
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      AppMeasurements.getResponsiveBorderRadius(context),
                    ),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AppMeasurements.getResponsiveBorderRadius(context),
                      ),
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppMeasurements.smallPadding,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cancel',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: AppMeasurements.getResponsiveFontSize(
                                  context,
                                  baseSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Logout Button
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.error,
                        Theme.of(context).colorScheme.error.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      AppMeasurements.getResponsiveBorderRadius(context),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AppMeasurements.getResponsiveBorderRadius(context),
                      ),
                      onTap: () {
                        Navigator.of(context).pop(); // Close dialog first
                        onConfirm(); // Then execute logout
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppMeasurements.smallPadding,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: AppMeasurements.getResponsiveFontSize(
                                  context,
                                  baseSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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