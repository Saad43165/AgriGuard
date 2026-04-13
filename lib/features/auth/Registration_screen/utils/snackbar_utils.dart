// lib/core/utils/snackbar_utils.dart
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/constants/app_routes.dart';

class SnackbarUtils {
  static void showSuccessSnackBar({
    required BuildContext context,
    required String message,
    String? title,
    int duration = 3,
  }) {
    _showSnackBar(
      context: context,
      message: message,
      title: title,
      isError: false,
      duration: duration,
    );
  }

  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
    String? title,
    int duration = 4,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context: context,
      message: message,
      title: title,
      isError: true,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  static void showDetailedSnackBar({
    required BuildContext context,
    required String title,
    required String message,
    required bool isSuccess,
    int duration = 6,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: isSuccess
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onError,
                  size: AppMeasurements.getResponsiveIconSizeSmall(context),
                ),
                SizedBox(
                  width: AppMeasurements.getResponsiveSmallPadding(context),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSuccess
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onError,
                    fontWeight: FontWeight.bold,
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: AppMeasurements.getResponsiveSmallPadding(context),
            ),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSuccess
                    ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9)
                    : Theme.of(context).colorScheme.onError.withValues(alpha: 0.9),
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: 12,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
        duration: Duration(seconds: duration),
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
          label: actionLabel,
          textColor: isSuccess
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onError,
          onPressed: onActionPressed,
        )
            : null,
      ),
    );
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required bool isError,
    String? title,
    int duration = 3,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: isError
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onPrimary,
              size: AppMeasurements.getResponsiveIconSizeSmall(context),
            ),
            SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isError
                            ? Theme.of(context).colorScheme.onError
                            : Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppMeasurements.getResponsiveFontSize(
                          context,
                          baseSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isError
                          ? Theme.of(context).colorScheme.onError
                          : Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: AppMeasurements.getResponsiveFontSize(
                        context,
                        baseSize: title != null ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
        duration: Duration(seconds: duration),
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
          label: actionLabel,
          textColor: isError
              ? Theme.of(context).colorScheme.onError
              : Theme.of(context).colorScheme.onPrimary,
          onPressed: onActionPressed,
        )
            : null,
      ),
    );
  }

  static void showImageSuccessSnackBar(BuildContext context) {
    showSuccessSnackBar(
      context: context,
      message: 'Profile image selected successfully',
    );
  }

  static void showImageErrorSnackBar(BuildContext context, String error) {
    showErrorSnackBar(
      context: context,
      message: 'Failed to select image: $error',
    );
  }

  static void showRegistrationSuccessSnackBar(BuildContext context) {
    showDetailedSnackBar(
      context: context,
      title: 'Registration Successful',
      message: 'Please check your email for a verification link. You must verify your email to log in.',
      isSuccess: true,
      actionLabel: 'Resend Email',
      onActionPressed: () {
        // Resend email logic will be handled in the screen
      },
    );
  }

  static void showEmailAlreadyInUseSnackBar(BuildContext context) {
    showErrorSnackBar(
      context: context,
      title: 'Email Already Registered',
      message: 'This email is already registered. Please login instead.',
      actionLabel: 'Login',
      onActionPressed: () {
        Navigator.pushNamed(context, AppRoutes.login);
      },
    );
  }

  static void showWeakPasswordSnackBar(BuildContext context) {
    showErrorSnackBar(
      context: context,
      title: 'Weak Password',
      message: 'Password is too weak. Please choose a stronger password.',
    );
  }

  static void showInvalidEmailSnackBar(BuildContext context) {
    showErrorSnackBar(
      context: context,
      title: 'Invalid Email',
      message: 'Invalid email address. Please check your email.',
    );
  }

  static void showUploadErrorSnackBar(BuildContext context, String error) {
    showErrorSnackBar(
      context: context,
      title: 'Upload Failed',
      message: 'Failed to upload profile image: $error',
    );
  }

  static void showNetworkErrorSnackBar(BuildContext context) {
    showErrorSnackBar(
      context: context,
      title: 'Network Error',
      message: 'Please check your internet connection and try again.',
    );
  }

  static void showUnexpectedErrorSnackBar(BuildContext context, String error) {
    showErrorSnackBar(
      context: context,
      title: 'Unexpected Error',
      message: 'Something went wrong: $error',
    );
  }
}