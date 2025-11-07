import 'package:flutter/material.dart';

class AppMeasurements {
  // Static constants (retained for backward compatibility)
  static const double defaultPadding = 24.0;
  static const double smallPadding = 16.0;
  static const double extraSmallPadding = 8.0;
  static const double borderRadius = 8.0;
  static const double cardElevation = 2.0;
  static const double iconSizeLarge = 60.0;
  static const double iconSizeMedium = 24.0;
  static const double scanCardWidth = 160.0;
  static const double scanCardHeight = 200.0;
  static const double scanImageHeight = 100.0;

  static double mediumPadding = 20.0;

  // Responsive sizing methods
  static double getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.05).clamp(8.0, 32.0); // 5% of screen width, with min/max limits
  }

  static double getResponsiveSmallPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.04).clamp(4.0, 24.0); // 4% of screen width, with min/max limits
  }

  static double getResponsiveExtraSmallPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.02).clamp(2.0, 16.0); // 2% of screen width, with min/max limits
  }

  static double getResponsiveBorderRadius(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.02).clamp(4.0, 16.0); // 2% of screen width, with min/max limits
  }

  static double getResponsiveCardElevation(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600 ? 3.0 : 2.0; // Slightly higher elevation for larger screens
  }

  static double getResponsiveIconSizeLarge(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.15).clamp(40.0, 100.0); // 15% of screen width, capped
  }

  static double getResponsiveIconSizeMedium(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.06).clamp(16.0, 40.0); // 6% of screen width, capped
  }

  static double getResponsiveIconSizeSmall(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.04).clamp(12.0, 24.0); // 4% of screen width, capped
  }

  static double getResponsiveScanCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.4).clamp(120.0, 300.0); // 40% of screen width, with min/max limits
  }

  static double getResponsiveScanCardHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight * 0.25).clamp(150.0, 400.0); // 25% of screen height, with min/max limits
  }

  static double getResponsiveScanImageHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight * 0.15).clamp(80.0, 200.0); // 15% of screen height, with min/max limits
  }

  static double getResponsiveFontSize(BuildContext context, {required double baseSize}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    return (baseSize * scaleFactor * (screenWidth / 375)).clamp(baseSize * 0.5, baseSize * 1.5); // Scale with min/max limits
  }

  static double getResponsiveSize(BuildContext context, {required double baseSize}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (baseSize * (screenWidth / 375)).clamp(baseSize * 0.5, baseSize * 1.5); // Scale with min/max limits
  }

  static double getResponsiveFabSize(BuildContext context, {required double baseSize}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (baseSize * (screenWidth / 375)).clamp(40.0, 72.0); // Scale FAB size, clamped between 40 and 72
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600; // Tablets or larger screens
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Optional: Add methods for height-based responsiveness if needed
  static double getResponsiveHeight(BuildContext context, {required double baseHeight}) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (baseHeight * (screenHeight / 667)).clamp(baseHeight * 0.5, baseHeight * 1.5); // Scale relative to 667px base height
  }

  static double getResponsiveWidth(BuildContext context, {required int baseWidth}) {
    final screenWidth = MediaQuery.of(context).size.width;
    const referenceWidth = 360.0;
    final scalingFactor = screenWidth / referenceWidth;
    return (baseWidth * scalingFactor).clamp(baseWidth * 0.8, baseWidth * 1.5);
  }
}