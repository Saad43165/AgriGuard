import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screens.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/scan/presentation/screens/capture_screen.dart';
import '../../features/scan/presentation/screens/image_edit_screen.dart';
import '../../features/scan/presentation/screens/results_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../core/constants/app_routes.dart';
import '../../core/errors/route_exception.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);
      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings);
      case AppRoutes.register:
        return _buildRoute(const RegisterScreen(), settings);
      case AppRoutes.forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);
      case AppRoutes.home:
        return _buildRoute(
          HomeScreen(userData: _getArgs<Map<String, dynamic>>(settings)),
          settings,
        );
      case AppRoutes.profile:
        return _buildRoute(
          ProfileScreen(userData: _getArgs<Map<String, dynamic>>(settings)),
          settings,
        );
      case AppRoutes.history:
        return _buildRoute(const HistoryScreen(), settings);
      case AppRoutes.scan:
        return _buildRoute(const CaptureScreen(), settings);
      case AppRoutes.imageEdit:
        final args = _getArgs<Map<String, dynamic>>(settings);
        final imagePath = args?['imagePath'] as String?;
        if (imagePath == null || imagePath.isEmpty) {
          return _buildErrorRoute('No image path provided');
        }
        return _buildRoute(ImageEditScreen(imagePath: imagePath), settings);
      case AppRoutes.results:
        final args = _getArgs<Map<String, dynamic>>(settings);
        final scanData = args?['scanData'] as Map<String, dynamic>? ?? {};
        return _buildRoute(ResultsScreen(scanData: scanData), settings);
      default:
        return _buildErrorRoute('No route defined for ${settings.name}');
    }
  }

  static MaterialPageRoute<T> _buildRoute<T>(
      Widget widget,
      RouteSettings settings,
      ) {
    return MaterialPageRoute<T>(
      builder: (_) => widget,
      settings: settings,
    );
  }

  static MaterialPageRoute<Scaffold> _buildErrorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text(message)),
      ),
    );
  }

  static T? _getArgs<T>(RouteSettings settings) {
    try {
      return settings.arguments as T?;
    } catch (e) {
      throw RouteException('Invalid arguments for route ${settings.name}');
    }
  }
}