// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Custom color palette for AgriGuard
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep green for agriculture
  static const Color secondaryGreen = Color(0xFF4CAF50); // Lighter green for accents
  static const Color accentYellow = Color(0xFFFFCA28); // Warm yellow for highlights
  static const Color backgroundLight = Color(0xFFFFFFFF); // White background (as original)
  static const Color backgroundDark = Color(0xFF121212); // Dark mode background
  static const Color textDark = Color(0xFF212121); // Near-black for light mode text
  static const Color textLight = Color(0xFFFFFFFF); // White for dark mode text
  static const Color surfaceLight = Color(0xFFF5F5F5); // Light surface for cards/inputs
  static const Color surfaceDark = Color(0xFF1E1E1E); // Dark surface for cards/inputs

  // Base text style for consistency
  static const TextStyle _baseTextStyle = TextStyle(
    fontFamily: 'Roboto', // Default Material font; customizable
    letterSpacing: 0.2,
  );

  // Comprehensive text theme for all Material 3 text styles
  static final TextTheme _textTheme = TextTheme(
    displayLarge: _baseTextStyle.copyWith(fontSize: 48, fontWeight: FontWeight.w700, color: textDark),
    displayMedium: _baseTextStyle.copyWith(fontSize: 36, fontWeight: FontWeight.w600, color: textDark),
    displaySmall: _baseTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w600, color: textDark),
    headlineLarge: _baseTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: textDark),
    headlineMedium: _baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
    headlineSmall: _baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
    titleLarge: _baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: textDark), // Matches original
    titleMedium: _baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w500, color: textDark),
    titleSmall: _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: textDark),
    bodyLarge: _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.normal, color: textDark), // Matches original
    bodyMedium: _baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.normal, color: textDark),
    bodySmall: _baseTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.normal, color: textDark),
    labelLarge: _baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
    labelMedium: _baseTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: textDark),
    labelSmall: _baseTextStyle.copyWith(fontSize: 10, fontWeight: FontWeight.w500, color: textDark),
  );

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true, // Modern Material 3 design
    primarySwatch: Colors.green, // Retained from original
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.green,
      accentColor: secondaryGreen,
      backgroundColor: backgroundLight,
      errorColor: Colors.red[700],
      cardColor: surfaceLight,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryGreen,
      secondary: secondaryGreen,
      tertiary: accentYellow,
      onPrimary: textLight,
      onSecondary: textLight,
      onBackground: textDark,
      surface: surfaceLight,
      onSurface: textDark,
    ),
    scaffoldBackgroundColor: backgroundLight, // Matches original Colors.white
    appBarTheme: const AppBarTheme(
      elevation: 0, // Matches original
      centerTitle: true, // Matches original
      backgroundColor: Colors.transparent,
      foregroundColor: textDark,
      iconTheme: IconThemeData(color: textDark), // Updated from Colors.black
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    ),
    textTheme: _textTheme,
    iconTheme: const IconThemeData(
      color: textDark,
      size: 24,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: textLight,
        textStyle: _textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryGreen,
        textStyle: _textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red[700]!, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red[700]!, width: 2),
      ),
      labelStyle: _textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
      hintStyle: _textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
      prefixIconColor: Colors.grey[600],
      suffixIconColor: Colors.grey[600],
      filled: true,
      fillColor: surfaceLight,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryGreen,
      circularTrackColor: Colors.grey[300],
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: surfaceLight,
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.grey,
      thickness: 1,
      space: 1,
    ),
  );

  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primarySwatch: Colors.green,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.green,
      accentColor: secondaryGreen,
      backgroundColor: backgroundDark,
      errorColor: Colors.red[400],
      cardColor: surfaceDark,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primaryGreen,
      secondary: secondaryGreen,
      tertiary: accentYellow,
      onPrimary: textLight,
      onSecondary: textLight,
      onBackground: textLight,
      surface: surfaceDark,
      onSurface: textLight,
    ),
    scaffoldBackgroundColor: backgroundDark,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: textLight,
      iconTheme: IconThemeData(color: textLight),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textLight,
      ),
    ),
    textTheme: _textTheme.copyWith(
      displayLarge: _textTheme.displayLarge?.copyWith(color: textLight),
      displayMedium: _textTheme.displayMedium?.copyWith(color: textLight),
      displaySmall: _textTheme.displaySmall?.copyWith(color: textLight),
      headlineLarge: _textTheme.headlineLarge?.copyWith(color: textLight),
      headlineMedium: _textTheme.headlineMedium?.copyWith(color: textLight),
      headlineSmall: _textTheme.headlineSmall?.copyWith(color: textLight),
      titleLarge: _textTheme.titleLarge?.copyWith(color: textLight),
      titleMedium: _textTheme.titleMedium?.copyWith(color: textLight),
      titleSmall: _textTheme.titleSmall?.copyWith(color: textLight),
      bodyLarge: _textTheme.bodyLarge?.copyWith(color: textLight),
      bodyMedium: _textTheme.bodyMedium?.copyWith(color: textLight),
      bodySmall: _textTheme.bodySmall?.copyWith(color: textLight),
      labelLarge: _textTheme.labelLarge?.copyWith(color: textLight),
      labelMedium: _textTheme.labelMedium?.copyWith(color: textLight),
      labelSmall: _textTheme.labelSmall?.copyWith(color: textLight),
    ),
    iconTheme: const IconThemeData(
      color: textLight,
      size: 24,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: textLight,
        textStyle: _textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryGreen,
        textStyle: _textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: secondaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red[400]!, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red[400]!, width: 2),
      ),
      labelStyle: _textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
      hintStyle: _textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
      prefixIconColor: Colors.grey[400],
      suffixIconColor: Colors.grey[400],
      filled: true,
      fillColor: surfaceDark,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: secondaryGreen,
      circularTrackColor: Colors.grey[700],
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: surfaceDark,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey[700],
      thickness: 1,
      space: 1,
    ),
  );

  // Helper method to get theme based on brightness
  static ThemeData getTheme({required Brightness brightness}) {
    return brightness == Brightness.light ? lightTheme : darkTheme;
  }
}