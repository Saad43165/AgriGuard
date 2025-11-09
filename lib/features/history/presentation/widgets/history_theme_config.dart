import 'package:flutter/material.dart';

/// Theme configuration specific to History feature
class HistoryThemeConfig {
  // Private constructor to prevent instantiation
  HistoryThemeConfig._();

  /// Helper method to get plant name badge colors
  static Map<String, dynamic> getPlantNameBadgeStyle(bool isDark) {
    return {
      'backgroundColor': isDark
          ? PlantNameColors.darkBackground
          .withOpacity(PlantNameColors.darkBackgroundOpacity)
          : PlantNameColors.lightBackground,
      'borderColor': isDark
          ? PlantNameColors.darkBorder
          .withOpacity(PlantNameColors.darkBorderOpacity)
          : PlantNameColors.lightBorder,
      'textColor': isDark ? PlantNameColors.darkText : PlantNameColors.lightText,
      'iconColor': isDark ? PlantNameColors.darkIcon : PlantNameColors.lightIcon,
    };
  }

  /// Helper method to get crop type badge colors
  static Map<String, dynamic> getCropTypeBadgeStyle(
      bool isDark,
      ColorScheme colorScheme,
      ) {
    return {
      'backgroundColor': isDark
          ? colorScheme.primaryContainer.withOpacity(0.6)
          : CropTypeColors.lightBackground,
      'borderColor': isDark
          ? colorScheme.primary.withOpacity(0.3)
          : CropTypeColors.lightBorder.withOpacity(CropTypeColors.lightBorderOpacity),
      'textColor':
      isDark ? colorScheme.onPrimaryContainer : CropTypeColors.lightText,
    };
  }

  /// Helper method to get confidence badge colors
  static Map<String, dynamic> getConfidenceBadgeStyle(bool isDark) {
    return {
      'backgroundColor': isDark
          ? ConfidenceColors.darkBackground
          .withOpacity(ConfidenceColors.darkBackgroundOpacity)
          : ConfidenceColors.lightBackground,
      'borderColor': isDark
          ? ConfidenceColors.darkBorder
          .withOpacity(ConfidenceColors.darkBorderOpacity)
          : ConfidenceColors.lightBorder
          .withOpacity(ConfidenceColors.lightBorderOpacity),
      'textColor':
      isDark ? ConfidenceColors.darkText : ConfidenceColors.lightText,
      'iconColor':
      isDark ? ConfidenceColors.darkIcon : ConfidenceColors.lightIcon,
    };
  }

  /// Helper method to get card colors
  static Map<String, dynamic> getCardStyle(bool isDark, ColorScheme colorScheme) {
    return {
      'backgroundColors': isDark
          ? [
        colorScheme.surface.withOpacity(0.8),
        colorScheme.surface.withOpacity(0.6),
      ]
          : [
        CardColors.lightBackground,
        CardColors.lightBackground.withOpacity(0.95),
      ],
      'borderColor': isDark
          ? colorScheme.outline.withOpacity(0.1)
          : CardColors.lightBorder.withOpacity(CardColors.lightBorderOpacity),
      'shadowColor': isDark
          ? colorScheme.primary.withOpacity(0.1)
          : Colors.black.withOpacity(0.08),
    };
  }

  /// Helper method to get background gradient
  static List<Color> getBackgroundGradient(bool isDark) {
    return isDark ? BackgroundColors.darkGradient : BackgroundColors.lightGradient;
  }

  /// Helper method to get text color
  static Color getTextColor(bool isDark, {bool isSecondary = false}) {
    if (isSecondary) {
      return isDark ? TextColors.darkSecondary : TextColors.lightSecondary;
    }
    return isDark ? TextColors.darkPrimary : TextColors.lightPrimary;
  }
}

/// Plant name badge colors
class PlantNameColors {
  // Dark Mode
  static const Color darkBackground = Color(0xFF1B5E20);
  static const double darkBackgroundOpacity = 0.4;
  static const Color darkBorder = Color(0xFF2E7D32);
  static const double darkBorderOpacity = 0.5;
  static const Color darkText = Color(0xFF81C784);
  static const Color darkIcon = Color(0xFF81C784);

  // Light Mode
  static const Color lightBackground = Color(0xFFE8F5E9);
  static const Color lightBorder = Color(0xFF66BB6A);
  static const Color lightText = Color(0xFF1B5E20);
  static const Color lightIcon = Color(0xFF2E7D32);
}

/// Crop type badge colors
class CropTypeColors {
  // Dark Mode - uses theme primaryContainer

  // Light Mode
  static const Color lightBackground = Color(0xFFE3F2FD);
  static const Color lightBorder = Color(0xFF1976D2);
  static const double lightBorderOpacity = 0.3;
  static const Color lightText = Color(0xFF0D47A1);
}

/// Confidence badge colors
class ConfidenceColors {
  // Dark Mode
  static const Color darkBackground = Color(0xFF4A148C);
  static const double darkBackgroundOpacity = 0.4;
  static const Color darkBorder = Color(0xFF7B1FA2);
  static const double darkBorderOpacity = 0.5;
  static const Color darkText = Color(0xFFCE93D8);
  static const Color darkIcon = Color(0xFFCE93D8);

  // Light Mode
  static const Color lightBackground = Color(0xFFF3E5F5);
  static const Color lightBorder = Color(0xFF9C27B0);
  static const double lightBorderOpacity = 0.3;
  static const Color lightText = Color(0xFF4A148C);
  static const Color lightIcon = Color(0xFF6A1B9A);
}

/// Card colors
class CardColors {
  // Dark Mode - uses theme surface with opacity

  // Light Mode
  static const Color lightBackground = Colors.white;
  static const Color lightBorder = Colors.grey;
  static const double lightBorderOpacity = 0.15;
}

/// Text colors
class TextColors {
  // Dark Mode
  static const Color darkPrimary = Colors.white;
  static const Color darkSecondary = Colors.grey;

  // Light Mode
  static const Color lightPrimary = Color(0xFF1A1A1A);
  static const Color lightSecondary = Colors.grey;
}

/// Background gradient colors
class BackgroundColors {
  // Dark Mode
  static const List<Color> darkGradient = [
    Color(0xFF0F0F23),
    Color(0xFF16213E),
    Color(0xFF0F0F23),
  ];

  // Light Mode
  static const List<Color> lightGradient = [
    Color(0xFFF8F9FA),
    Color(0xFFFFFFFF),
    Color(0xFFF8F9FA),
  ];
}