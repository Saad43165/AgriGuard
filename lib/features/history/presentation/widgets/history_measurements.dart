import 'package:flutter/material.dart';

import '../../../../core/constants/app_measurements.dart';

/// Measurements specific to History feature
class HistoryMeasurements {
  // Private constructor
  HistoryMeasurements._();

  // Card measurements
  static const double cardBorderRadius = 16.0;
  static const double cardPadding = 12.0;
  static const double cardSpacing = 12.0;
  static const double cardBlurRadius = 12.0;
  static const Offset cardShadowOffset = Offset(0, 4);

  // Image measurements
  static const double imageSize = 70.0;
  static const double imageBorderRadius = 12.0;
  static const double imageBlurRadius = 8.0;
  static const Offset imageShadowOffset = Offset(0, 2);
  static const double placeholderIconSize = 28.0;

  // Badge measurements
  static const double badgeHorizontalPadding = 8.0;
  static const double badgeVerticalPadding = 3.0;
  static const double badgeBorderRadius = 6.0;
  static const double badgeBorderWidth = 1.0;
  static const double badgeIconSize = 11.0;
  static const double badgeSpacing = 6.0;

  // Plant name badge
  static const double plantNameBadgeIconSize = 11.0;
  static const double plantNameBadgeFontSize = 10.0;

  // Crop type badge
  static const double cropTypeBadgeFontSize = 10.0;

  // Confidence badge
  static const double confidenceBadgeIconSize = 10.0;
  static const double confidenceBadgeFontSize = 10.0;
  static const double confidenceBadgeHorizontalPadding = 7.0;

  // Text measurements
  static const double titleFontSize = 14.0;
  static const double titleLineHeight = 1.2;
  static const double timestampIconSize = 12.0;
  static const double timestampFontSize = 11.0;

  // Delete button
  static const double deleteButtonSize = 20.0;
  static const double deleteButtonMinWidth = 36.0;
  static const double deleteButtonMinHeight = 36.0;

  // Header measurements
  static const double headerMarginHorizontal = 16.0;
  static const double headerMarginTop = 16.0;
  static const double headerMarginBottom = 12.0;
  static const double headerPadding = 20.0;
  static const double headerBorderRadius = 20.0;
  static const double headerIconSize = 32.0;
  static const double headerIconPadding = 12.0;
  static const double headerSpacing = 12.0;
  static const double headerSmallSpacing = 4.0;
  static const double scanCountBadgePadding = 12.0;
  static const double scanCountBadgeVerticalPadding = 6.0;
  static const double scanCountBadgeBorderRadius = 20.0;

  // Content padding
  static const double contentPaddingHorizontal = 16.0;
  static const double contentPaddingTop = 8.0;
  static const double contentPaddingBottom = 24.0;

  // Spacing
  static const double contentSpacingSmall = 4.0;
  static const double contentSpacingMedium = 6.0;
  static const double contentSpacingLarge = 8.0;
  static const double contentSpacingExtraLarge = 12.0;

  // Loading/Error state
  static const double loadingPadding = 48.0;
  static const double errorPadding = 32.0;
  static const double errorIconSize = 64.0;
  static const double errorSpacing = 16.0;
  static const double errorSmallSpacing = 8.0;
  static const double errorButtonSpacing = 20.0;

  // Dialog
  static const double dialogBorderRadius = 20.0;

  // SnackBar
  static const double snackBarBorderRadius = 12.0;
  static const double snackBarMargin = 16.0;

  /// Get responsive measurements based on screen size
  static double getResponsiveCardPadding(BuildContext context) {
    return AppMeasurements.getResponsiveSize(context, baseSize: cardPadding);
  }

  static double getResponsiveImageSize(BuildContext context) {
    return AppMeasurements.getResponsiveSize(context, baseSize: imageSize);
  }

  static double getResponsiveHeaderPadding(BuildContext context) {
    return AppMeasurements.getResponsiveSize(context, baseSize: headerPadding);
  }

  static double getResponsiveHeaderIconSize(BuildContext context) {
    return AppMeasurements.getResponsiveIconSizeMedium(context);
  }

  static double getResponsiveTitleFontSize(BuildContext context) {
    return AppMeasurements.getResponsiveFontSize(
      context,
      baseSize: titleFontSize,
    );
  }

  static double getResponsiveBadgeFontSize(BuildContext context) {
    return AppMeasurements.getResponsiveFontSize(
      context,
      baseSize: cropTypeBadgeFontSize,
    );
  }

  /// Check if screen is large
  static bool isLargeScreen(BuildContext context) {
    return AppMeasurements.isLargeScreen(context);
  }
}