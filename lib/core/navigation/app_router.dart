import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screens.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/scan/presentation/screens/capture_screen.dart';
import '../../features/scan/presentation/screens/image_edit_screen.dart';
import '../../features/scan/presentation/screens/results_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../core/constants/app_routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => HomeScreen(userData: args),
          settings: settings,
        );
      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(userData: args),
          settings: settings,
        );
      case AppRoutes.history:
        return MaterialPageRoute(
          builder: (_) => const HistoryScreen(),
          settings: settings,
        );
      case AppRoutes.scan:
        return MaterialPageRoute(
          builder: (_) => const CaptureScreen(),
          settings: settings,
        );
      case AppRoutes.imageEdit:
        final imagePath = args?['imagePath'] as String? ?? '';
        if (imagePath.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('No image path provided')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ImageEditScreen(imagePath: imagePath),
          settings: settings,
        );
      case AppRoutes.results:
        final scanData = args?['scanData'] as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ResultsScreen(scanData: scanData),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}