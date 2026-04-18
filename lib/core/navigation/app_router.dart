// app_router.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/HelpSupport/help_support_screen.dart';
import '../../features/ResultScreen/presentation/results_screen.dart';
import '../../features/Settings/presentation/settings_screen.dart';
import '../../features/auth/Login_Screen/login_screens.dart';
import '../../features/auth/Registration_screen/register_screen.dart';
import '../../features/auth/Forget_Pass_Screen/forgot_password_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../core/constants/app_routes.dart';
import '../navigation/main_navigation_screen.dart';
import '../../features/auth/Login_Screen/services/guest_service.dart';
import '../../features/chatbot/chatbot_screen.dart';
import '../../features/HelpSupport/bug_report_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/farm_diary/farm_diary_screen.dart';
import '../../features/crop_calendar/crop_calendar_screen.dart';
import '../../features/disease_library/disease_library_screen.dart';
import '../../features/capture/presentations/capture_screen.dart';

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
    final isGuest = GuestService().isGuestMode;

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

    // MAIN NAVIGATION ROUTES — always clear stack to prevent back-stack buildup
      case AppRoutes.home:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => MainNavigationScreen(initialIndex: 0, userData: args ?? {}),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );

      case AppRoutes.scan:
        final startAdvanced = args?['startAdvanced'] as bool? ?? false;
        final plantHint = args?['plantHint'] as String?;
        if (startAdvanced || plantHint != null) {
          return buildLightRoute(CaptureScreen(
            startAdvanced: startAdvanced,
            plantHint: plantHint,
          ));
        }
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => MainNavigationScreen(
            initialIndex: 0,
            userData: {...(args ?? {}), 'openCamera': true},
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );

      case AppRoutes.profile:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => MainNavigationScreen(initialIndex: 3, userData: args ?? {}),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
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

      case AppRoutes.chatbot:
        return buildLightRoute(const ChatbotScreen());

      case AppRoutes.bugReport:
        return buildLightRoute(const BugReportScreen());

      case AppRoutes.analytics:
        return buildLightRoute(const AnalyticsScreen());

      case AppRoutes.farmDiary:
        return buildLightRoute(const FarmDiaryScreen());

      case AppRoutes.cropCalendar:
        return buildLightRoute(const CropCalendarScreen());

      case AppRoutes.diseaseLibrary:
        return buildLightRoute(const DiseaseLibraryScreen());

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
