import 'package:flutter/material.dart';

class ResultScreenConstants {
  // Timing constants
  static const Duration advancedSearchDelay = Duration(seconds: 4);
  static const Duration advancedSearchDuration = Duration(seconds: 8);
  static const Duration animationDuration = Duration(milliseconds: 800);
  static const Duration scaleAnimationDuration = Duration(milliseconds: 600);

  // Confidence thresholds
  static const double minimumConfidence = 5.0;
  static const double nonLeafConfidence = 95.0;
  static const double leafDetectionThreshold = 40.0;

  // IDs and prefixes
  static const String scanIdPrefix = 'ondevice_';
  static const String advancedScanPrefix = 'advanced_';

  // Colors
  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color secondaryPurple = Color(0xFF8B5CF6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);

  // Gradients
  static const List<Color> darkGradient = [
    Color(0xFF0F0F23),
    Color(0xFF16213E),
    Color(0xFF1A1A2E),
    Color(0xFF0F0F23),
  ];

  static const List<double> gradientStops = [0.0, 0.3, 0.7, 1.0];

  // Animation values
  static const double scaleBegin = 0.8;
  static const double scaleEnd = 1.0;
  static const Curve scaleCurve = Curves.elasticOut;

  // Image dimensions
  static const double imageHeight = 280;
  static const double imageBorderRadius = 16;

  // Padding and spacing
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double largePadding = 20;
  static const double bottomButtonPadding = 100;

  // Text styles
  static const double titleFontSize = 18;
  static const double bodyFontSize = 14;
  static const double smallFontSize = 12;
}