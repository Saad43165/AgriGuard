// lib/main.dart
import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'core/navigation/app_router.dart'; // Updated import

void main() {
  runApp(const AgriGuardApp());
}

class AgriGuardApp extends StatelessWidget {
  const AgriGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriGuard',
      theme: AppTheme.lightTheme,
      initialRoute: '/splash', // Ensure this matches a defined route
      onGenerateRoute: AppRouter.generateRoute, // Ensure AppRouter is defined
      debugShowCheckedModeBanner: false,
    );
  }
}