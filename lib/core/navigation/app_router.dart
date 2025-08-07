import 'package:flutter/material.dart';
import '../../features/HelpSupport/help_support_screen.dart';
import '../../features/Profile/presentation/profile_screen.dart';
import '../../features/ResultScreen/presentation/screens/results_screen.dart';
import '../../features/Settings/presentation/settings_screen.dart';
import '../../features/auth/presentation/screens/login_screens.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/capture/presentations/capture_screen.dart';
import '../../features/edit/presentation/screens/image_edit_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../core/constants/app_routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    // Helper method for consistent animations
    Route<dynamic> buildAnimatedRoute({
      required Widget page,
      Duration transitionDuration = const Duration(milliseconds: 500),
    }) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide animation
          const beginSlide = Offset(-1.0, 0.0); // Slide from left
          const endSlide = Offset.zero;
          const curve = Curves.easeInOut;
          var slideTween = Tween(begin: beginSlide, end: endSlide).chain(
              CurveTween(curve: curve));
          var slideAnimation = animation.drive(slideTween);

          // Fade animation
          var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          // Scale animation
          var scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.75,
                  curve: Curves.elasticOut), // Scale completes in 375ms
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            ),
          );
        },
        transitionDuration: transitionDuration,
      );
    }

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case AppRoutes.login:
        return buildAnimatedRoute(page: const LoginScreen());
      case AppRoutes.register:
        return buildAnimatedRoute(page: const RegisterScreen());
      case AppRoutes.forgotPassword:
        return buildAnimatedRoute(page: const ForgotPasswordScreen());
      case AppRoutes.home:
        return buildAnimatedRoute(page: HomeScreen(userData: args));
      case AppRoutes.profile:
        return buildAnimatedRoute(page: ProfileScreen(userData: args));
      case AppRoutes.history:
        return buildAnimatedRoute(page: const HistoryScreen());
      case AppRoutes.scan:
        return buildAnimatedRoute(page: const CaptureScreen());
      case AppRoutes.imageEdit:
        final imagePath = args?['imagePath'] as String? ?? '';
        if (imagePath.isEmpty) {
          return MaterialPageRoute(
            builder: (_) =>
            const Scaffold(
              body: Center(child: Text('No image path provided')),
            ),
          );
        }
        return buildAnimatedRoute(page: ImageEditScreen(imagePath: imagePath));
      case AppRoutes.results:
        final scanData = args?['scanData'] as Map<String, dynamic>? ?? {};
        return buildAnimatedRoute(page: ResultsScreen(scanData: scanData));
      case AppRoutes.settings:
        return buildAnimatedRoute(page: const SettingsScreen());
      case AppRoutes.help:
        return buildAnimatedRoute(page: const HelpAndSupportScreen());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              Scaffold(
                body: Center(
                    child: Text('No route defined for ${settings.name}')),
              ),
        );
    }
  }}