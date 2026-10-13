import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_routes.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'package:agriguard_fyp/core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  const SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // Light status bar for white splash
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      widget.isLoggedIn ? AppRoutes.home : AppRoutes.onboard,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Colors.white;
    const titleColor = AppColors.lightOnSurface;
    const subtitleColor = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // subtle top glow to keep premium feel on white background
          PositionedDirectional(
            top: -120,
            start: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          PositionedDirectional(
            top: -100,
            end: -90,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.06),
              ),
            ),
          ),

          FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppLogo(
                      size: 120,
                      isRounded: false,
                      backgroundColor: Colors.white,
                      shadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.16),
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'AgriGuard',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Advanced Plant Intelligence',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 70),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          PositionedDirectional(
            bottom: 34,
            start: 0,
            end: 0,
            child: FadeTransition(
              opacity: _fade,
              child: Center(
                child: Text(
                  'v2.1.0 Premium Edition',
                  style: TextStyle(
                    color: subtitleColor.withValues(alpha: 0.7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}