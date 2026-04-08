import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/navigation/app_router.dart';
import 'core/widgets/app_themes.dart';
import 'core/services/notification_service.dart';
import 'core/services/translation_service.dart';
import 'core/services/localization_service.dart';
import 'features/auth/Login_Screen/services/guest_service.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (API keys, models, etc.)
  // Safe to call even if .env is missing in release builds.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Guest Service
  await GuestService().initialize();

  // Initialize Notifications
  await NotificationService().initialize();

  // Initialize Translation Services
  final translationService = TranslationService();
  await translationService.loadLanguage();

  final localizationService = LocalizationService();
  await localizationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: translationService),
        ChangeNotifierProvider.value(value: localizationService),
      ],
      child: const AgriGuardApp(),
    ),
  );
}

Future<void> clearImagePickerCache() async {
  final cacheDir = await getTemporaryDirectory();
  if (await cacheDir.exists()) {
    await cacheDir.delete(recursive: true);
  }
}

class AgriGuardApp extends StatelessWidget {
  final ThemeData? themeOverride;
  final Widget? homeOverride;
  final Stream<User?>? authStateChangesOverride;

  const AgriGuardApp({
    super.key,
    this.themeOverride,
    this.homeOverride,
    this.authStateChangesOverride,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppRouter.navigatorKey,
      title: 'AgriGuard',
      theme: themeOverride ?? Provider.of<ThemeProvider>(context).currentTheme,
      debugShowCheckedModeBanner: false,
      home: homeOverride ??
          StreamBuilder<User?>(
            stream: authStateChangesOverride ??
                FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return SplashScreen(isLoggedIn: snapshot.hasData);
            },
          ),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}