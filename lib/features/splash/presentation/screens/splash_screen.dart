import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_routes.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';

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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2000), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    if (widget.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboard);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 20),
                const Text('AgriGuard',
                    style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w900,
                      color: AppColors.lightOnSurface, letterSpacing: -1,
                    )),
                const SizedBox(height: 6),
                const Text('Plant Disease Detection',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: AppColors.lightCaption,
                    )),
                const SizedBox(height: 60),
                SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
