import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — single source of truth for the whole app
// Inspired by clean botanical app design: forest green, white, minimal
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  // Brand — forest green (botanical, professional)
  static const primary   = Color(0xFF2D6A4F); // deep forest green
  static const secondary = Color(0xFF40916C); // medium green accent

  // Light surface palette — clean white/grey
  static const lightBg        = Color(0xFFF5F5F5); // very light grey
  static const lightSurface   = Color(0xFFFFFFFF);
  static const lightCard      = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1B2B1E); // very dark green-black
  static const lightSubtext   = Color(0xFF4A5568); // readable mid-grey
  static const lightCaption   = Color(0xFF718096);
  static const lightBorder    = Color(0xFFE8E8E8); // very subtle border

  // Dark surface palette
  static const darkBg        = Color(0xFF0D1117);
  static const darkSurface   = Color(0xFF161B22);
  static const darkCard      = Color(0xFF1C2333);
  static const darkOnSurface = Color(0xFFE6EDF3);
  static const darkSubtext   = Color(0xFFB0BAC9);
  static const darkCaption   = Color(0xFF8B949E);
  static const darkBorder    = Color(0xFF30363D);

  // Semantic
  static const success  = Color(0xFF2D6A4F); // same as primary
  static const warning  = Color(0xFFF59E0B);
  static const error    = Color(0xFFEF4444);
  static const info     = Color(0xFF40916C);  // medium green

  // Extra botanical colors
  static const primaryLight = Color(0xFFD8F3DC); // very light green tint
  static const primaryDark  = Color(0xFF1B4332); // darkest green
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _themeMode = 'light'; // 'light', 'dark', 'system'
  ThemeData _currentTheme;

  ThemeProvider() : _currentTheme = AppTheme.lightTheme {
    _loadTheme();
  }

  ThemeData get currentTheme {
    if (_themeMode == 'system') {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
    }
    return _currentTheme;
  }

  bool get isDarkMode => _isDarkMode;
  String get themeMode => _themeMode;

  static ThemeProvider of(BuildContext context) =>
      Provider.of<ThemeProvider>(context, listen: false);

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode') ?? (prefs.getBool('isDarkMode') == true ? 'dark' : 'light');
    _themeMode = saved;
    _isDarkMode = saved == 'dark';
    _currentTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    _isDarkMode = mode == 'dark';
    _currentTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode);
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? 'dark' : 'light');
  }
}

class AppTheme {
  // ── Light Theme ─────────────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBg,

    colorScheme: const ColorScheme.light(
      primary:                AppColors.primary,
      onPrimary:              Colors.white,
      primaryContainer:       AppColors.primaryLight,
      onPrimaryContainer:     AppColors.primaryDark,
      secondary:             AppColors.secondary,
      onSecondary:           Colors.white,
      secondaryContainer:    AppColors.primaryLight,
      onSecondaryContainer: AppColors.primaryDark,
      tertiary:              AppColors.secondary,
      tertiaryContainer:    AppColors.primaryLight,
      onTertiaryContainer:   AppColors.primaryDark,
      surface:               AppColors.lightSurface,
      onSurface:            AppColors.lightOnSurface,
      onSurfaceVariant:     AppColors.lightCaption,
      error:                AppColors.error,
      onError:              Colors.white,
      outline:              AppColors.lightBorder,
      outlineVariant:       AppColors.lightBorder,
      surfaceContainerLowest:  Color(0xFFFFFFFF),
      surfaceContainerLow:   Color(0xFFF5F5F5),
      surfaceContainer:      Color(0xFFFAFAFA),
      surfaceContainerHigh: Color(0xFFEEEEEE),
      surfaceContainerHighest: Color(0xFFE8E8E8),
      surfaceTint:           AppColors.primary,
    ),

    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.lightOnSurface, letterSpacing: -1.0),
      displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.lightOnSurface, letterSpacing: -0.5),
      headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.lightOnSurface, letterSpacing: -0.5),
      headlineMedium:TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.lightOnSurface),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.lightOnSurface),
      titleLarge:    TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.lightOnSurface),
      titleMedium:   TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.lightOnSurface),
      titleSmall:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightSubtext),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.lightOnSurface, height: 1.6),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.lightSubtext,   height: 1.5),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.lightCaption,   height: 1.4),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightOnSurface, letterSpacing: 0.1),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightSubtext),
      labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.lightCaption,   letterSpacing: 0.3),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightOnSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.lightOnSurface,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.lightOnSurface, size: 22),
    ),

    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), // pill shape
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        backgroundColor: Colors.white,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50), // pill input
        borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.lightSubtext, fontSize: 14, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: AppColors.lightCaption, fontSize: 14),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
    ),

    iconTheme: const IconThemeData(color: AppColors.lightOnSurface, size: 22),

    dividerTheme: const DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
      space: 1,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryLight,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.lightOnSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightOnSurface),
      contentTextStyle: const TextStyle(fontSize: 14, color: AppColors.lightSubtext, height: 1.5),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 1,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.primary : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.lightBorder),
    ),
  );

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBg,

    colorScheme: const ColorScheme.dark(
      primary:               AppColors.primary,
      onPrimary:            Colors.white,
      primaryContainer:      AppColors.primaryDark,
      onPrimaryContainer:   Color(0xFFB5E6C4),
      secondary:            AppColors.secondary,
      onSecondary:         Colors.white,
      secondaryContainer:   AppColors.primaryDark,
      onSecondaryContainer: Color(0xFFB5E6C4),
      tertiary:             AppColors.secondary,
      tertiaryContainer:   AppColors.primaryDark,
      onTertiaryContainer:  Color(0xFFB5E6C4),
      surface:              AppColors.darkSurface,
      onSurface:            AppColors.darkOnSurface,
      onSurfaceVariant:    AppColors.darkCaption,
      error:                AppColors.error,
      onError:              Colors.white,
      outline:              AppColors.darkBorder,
      outlineVariant:      AppColors.darkBorder,
      surfaceContainerLowest: Color(0xFF0D1117),
      surfaceContainerLow:  Color(0xFF161B22),
      surfaceContainer:     Color(0xFF1C2333),
      surfaceContainerHigh: Color(0xFF21262D),
      surfaceContainerHighest: Color(0xFF30363D),
      surfaceTint:          AppColors.primary,
    ),

    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.darkOnSurface, letterSpacing: -1.0),
      displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.darkOnSurface, letterSpacing: -0.5),
      headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.darkOnSurface, letterSpacing: -0.5),
      headlineMedium:TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkOnSurface),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkOnSurface),
      titleLarge:    TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkOnSurface),
      titleMedium:   TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkOnSurface),
      titleSmall:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkSubtext),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkOnSurface, height: 1.5),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.darkSubtext,   height: 1.5),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.darkCaption,   height: 1.4),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkOnSurface, letterSpacing: 0.3),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkSubtext),
      labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.darkCaption,   letterSpacing: 0.5),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkOnSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.darkOnSurface,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.darkOnSurface, size: 22),
    ),

    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.darkSubtext, fontSize: 14, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: AppColors.darkCaption, fontSize: 14),
errorStyle: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
    ),

    iconTheme: const IconThemeData(color: AppColors.darkOnSurface, size: 22),

    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkCard,
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.darkOnSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkOnSurface),
      contentTextStyle: const TextStyle(fontSize: 14, color: AppColors.darkSubtext, height: 1.5),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 1,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.primary : AppColors.darkSubtext),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.darkBorder),
    ),
  );
}
