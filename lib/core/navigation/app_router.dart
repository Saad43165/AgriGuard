// app_router.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/HelpSupport/help_support_screen.dart';
import '../../features/ResultScreen/presentation/screens/results_screen.dart';
import '../../features/Settings/presentation/settings_screen.dart';
import '../../features/auth/Login_Screen/login_screens.dart';
import '../../features/auth/Registration_screen/register_screen.dart';
import '../../features/auth/Forget_Pass_Screen/forgot_password_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../core/constants/app_routes.dart';
import '../navigation/main_navigation_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    Route<dynamic> buildLightRoute(Widget page) {
      return PageRouteBuilder(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, _) => page,
        transitionsBuilder: (context, animation, _, child) {
          final slide = Tween<Offset>(begin: const Offset(0.3, 0.0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
        },
      );
    }

    // AUTH GUARD
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => SplashScreen(isLoggedIn: isLoggedIn));

      case AppRoutes.onboard:
        return buildLightRoute(const OnboardingScreen());

      case AppRoutes.login:
        if (isLoggedIn) {
          return buildLightRoute(MainNavigationScreen(userData: {}));
        }
        return buildLightRoute(const LoginScreen());

      case AppRoutes.register:
        if (isLoggedIn) {
          return buildLightRoute(MainNavigationScreen(userData: {}));
        }
        return buildLightRoute(const RegisterScreen());

      case AppRoutes.forgotPassword:
        if (isLoggedIn) {
          return buildLightRoute(MainNavigationScreen(userData: {}));
        }
        return buildLightRoute(const ForgotPasswordScreen());

    // MAIN NAVIGATION ROUTES - All go to MainNavigationScreen with different tabs
      case AppRoutes.home:
        return buildLightRoute(
          MainNavigationScreen(
            initialIndex: 0,
            userData: args ?? {},
          ),
        );

      case AppRoutes.scan:
        return buildLightRoute(
          MainNavigationScreen(
            initialIndex: 1,
            userData: args ?? {},
          ),
        );

      case AppRoutes.profile:
        return buildLightRoute(
          MainNavigationScreen(
            initialIndex: 2,
            userData: args ?? {},
          ),
        );

    // SEPARATE SCREENS (Not part of bottom navigation)
      case AppRoutes.history:
        return buildLightRoute(const HistoryScreen());

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Screen not found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Route: ${settings.name}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                    },
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}