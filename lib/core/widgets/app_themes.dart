import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  ThemeData _currentTheme;

  ThemeProvider() : _currentTheme = AppTheme.darkTheme {
    _loadTheme();
  }

  ThemeData get currentTheme => _currentTheme;

  bool get isDarkMode => _isDarkMode;

  static ThemeProvider of(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _currentTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    _currentTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF00D4AA), // Vibrant teal as the primary color
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00D4AA), // Teal for primary actions
      onPrimary: Colors.white, // White text on primary background
      secondary: Color(0xFF6C63FF), // Purple for secondary actions
      onSecondary: Colors.white, // White text on secondary background
      surface: Color(0xFFF5F7FA), // Light gray surface for cards and sheets
      onSurface: Color(0xFF2C3E50), // Dark slate for text, better contrast
      background: Color(0xFFF9FBFD), // Very light background for a clean look
      error: Color(0xFFD32F2F), // Vibrant red for errors
      onError: Colors.white, // White text on error background
    ),
    scaffoldBackgroundColor: const Color(0xFFF9FBFD), // Consistent with background
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50), // Darker text for headings
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50), // Consistent dark text
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        color: Color(0xFF34495E), // Slightly lighter for body text, good contrast
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Color(0xFF34495E), // Consistent with bodyLarge
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        color: Color(0xFF7F8C8D), // Subtle gray for captions
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFF00D4AA), // Teal buttons
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00D4AA), // Teal background
        foregroundColor: Colors.white, // White text
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7FAFC), // Very light fill for inputs
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB0BEC5)), // Light gray border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB0BEC5)), // Consistent border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2), // Teal focus
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)), // Red for errors
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2), // Bold red
      ),
      labelStyle: const TextStyle(color: Color(0xFF34495E)), // Darker label for contrast
      hintStyle: const TextStyle(color: Color(0xFF7F8C8D)), // Subtle hint text
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF2C3E50), // Dark slate for icons
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF9FBFD), // Matches background
      foregroundColor: Color(0xFF2C3E50), // Dark text for app bar
      elevation: 0, // No shadow for a flat look
    ),
    cardTheme: const CardTheme(
      color: Color(0xFFF5F7FA), // Light surface for cards
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF00D4AA),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00D4AA),
      onPrimary: Colors.black,
      secondary: Color(0xFF6C63FF),
      onSecondary: Colors.black,
      surface: Color(0xFF1A1A2E),
      onSurface: Colors.white,
      background: Color(0xFF16213E),
      error: Color(0xFFCF6679),
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F23),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFF00D4AA),
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00D4AA),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCF6679)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCF6679), width: 2),
      ),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
  );
}