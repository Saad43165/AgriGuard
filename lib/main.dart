import 'package:agriguard_fyp/features/auth/Login_Screen/login_screens.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/navigation/app_router.dart';
import 'core/constants/app_routes.dart';
import 'core/widgets/app_themes.dart';
import 'features/home/screens/home_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
  const AgriGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppRouter.navigatorKey, // Add this line
      title: 'AgriGuard',
      theme: Provider.of<ThemeProvider>(context).currentTheme,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            // User is logged in, go to HomeScreen
            return const SplashScreen();
          }
          // User is not logged in, go to SplashScreen
          return const SplashScreen();
        },
      ),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}