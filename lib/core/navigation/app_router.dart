import 'package:flutter/material.dart';
import '../../features/HelpSupport/help_support_screen.dart';
import '../../features/Profile/presentation/profile_screen.dart';
import '../../features/ResultScreen/presentation/screens/results_screen.dart';
import '../../features/Settings/presentation/settings_screen.dart';
import '../../features/auth/Login_Screen/login_screens.dart';
import '../../features/auth/Registration_screen/register_screen.dart';
import '../../features/auth/Forget_Pass_Screen/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/capture/presentations/capture_screen.dart';
import '../../features/edit/presentation/image_edit_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../core/constants/app_routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    // Light & fast: tiny slide + fade (200ms)
    Route<dynamic> buildLightRoute(Widget page) {
      return PageRouteBuilder(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, _) => page,
        transitionsBuilder: (context, animation, _, child) {
          // Very subtle slide from right
          final slide = Tween<Offset>(
            begin: const Offset(0.3, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          // Quick fade
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
      );
    }

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case AppRoutes.onboard:
        return buildLightRoute(const OnboardingScreen());

      case AppRoutes.login:
        return buildLightRoute(const LoginScreen());

      case AppRoutes.register:
        return buildLightRoute(const RegisterScreen());

      case AppRoutes.forgotPassword:
        return buildLightRoute(const ForgotPasswordScreen());

      case AppRoutes.home:
        return buildLightRoute(HomeScreen(userData: args));

      case AppRoutes.profile:
        return buildLightRoute(
          ProfileScreen(
            userData: args is Map<String, dynamic> ? args : null,
          ),
        );

      case AppRoutes.history:
        return buildLightRoute(const HistoryScreen());

      case AppRoutes.scan:
        return buildLightRoute(const CaptureScreen());

      case AppRoutes.imageEdit:
        final imagePath = args?['imagePath'] as String? ?? '';
        if (imagePath.isEmpty) {
          return buildLightRoute(
            const Scaffold(
              body: Center(child: Text('No image path provided')),
            ),
          );
        }
        return buildLightRoute(ImageEditScreen(imagePath: imagePath));

      case AppRoutes.results:
        final scanData = args?['scanData'] as Map<String, dynamic>? ?? {};
        return buildLightRoute(ResultsScreen(scanData: scanData));

      case AppRoutes.settings:
        return buildLightRoute(const SettingsScreen());

      case AppRoutes.help:
        return buildLightRoute(const HelpAndSupportScreen());

      default:
        return buildLightRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}