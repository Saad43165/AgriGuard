// lib/core/navigation/app_router.dart
import 'package:agriguard_fyp/features/scan/presentation/screens/capture_screen.dart';
import 'package:agriguard_fyp/features/scan/presentation/screens/image_edit_screen.dart';
import 'package:flutter/material.dart';
import '../../features/Profile/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/login_screens.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../core/constants/app_constants.dart';
import '../../features/scan/presentation/screens/results_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart'; // Import for AppRoutes

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen()); // Add SplashScreen if defined
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case AppRoutes.scan:
        return MaterialPageRoute(builder: (_) => CaptureScreen());
      case AppRoutes.imageEdit:
        final args = settings.arguments as Map<String, dynamic>?;
        final imagePath = args?['imagePath'] as String? ?? '';
        debugPrint('ImageEdit route received imagePath: $imagePath');
        if (imagePath.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('No image path provided')),
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => ImageEditScreen(imagePath: imagePath));
      case AppRoutes.results:
        final args = settings.arguments as Map<String, dynamic>?;
        final scanData = args?['scanData'] as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(builder: (_) => ResultsScreen(scanData: scanData));
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}