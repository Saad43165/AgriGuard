import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart';
import 'glass_card.dart';

class LogoutConfirmationDialogContent extends StatelessWidget {
  final VoidCallback onConfirm;

  const LogoutConfirmationDialogContent({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent, // ← FIX: Make dialog background transparent
      elevation: 0, // ← FIX: Remove default dialog shadow
      insetPadding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
      child: GlassCard(
        useSolidBackground: true,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: colorScheme.error,
                  size: 36,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                'Log Out?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'You will need to log in again to access your account and scan history.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppMeasurements.getResponsiveBorderRadius(context),
                          ),
                        ),
                        side: BorderSide(
                          color: colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Logout Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog first
                        onConfirm(); // Then execute logout
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppMeasurements.getResponsiveBorderRadius(context),
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Log Out',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onError,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: colorScheme.onError,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}