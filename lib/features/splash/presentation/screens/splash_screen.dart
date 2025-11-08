import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';
import '../widget/animation_orbs_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  late AnimationController _leafController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _leafAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _leafController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );
    _leafAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _leafController, curve: Curves.elasticOut),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _startAnimations();
    _navigateToNext();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _fadeController.forward();
      _scaleController.forward();

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        _slideController.forward();
        _rotateController.forward();

        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _leafController.forward();
          _progressController.forward();
        }
      }
    }
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboard');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    _leafController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF0F0F23),
              const Color(0xFF16213E),
              const Color(0xFF1A1A2E),
              const Color(0xFF0F0F23),
            ]
                : [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.95),
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.background,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated orbs background
            AnimatedOrbsBackground(scaleAnimation: _scaleAnimation),

            // Floating orbs (consistent with home screen)
            ...List.generate(8, (index) => _buildFloatingOrb(index)),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(padding),
                      child: _buildMainCard(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingOrb(int index) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Positioned(
          top: (index * 120.0) % MediaQuery.of(context).size.height,
          left: (index * 80.0) % MediaQuery.of(context).size.width,
          child: Transform.scale(
            scale: _scaleAnimation.value * (0.8 + (index * 0.1)),
            child: Container(
              width: AppMeasurements.getResponsiveSize(context, baseSize: 60 + (index * 15.0)),
              height: AppMeasurements.getResponsiveSize(context, baseSize: 60 + (index * 15.0)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (index.isEven
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary)
                        .withOpacity(0.15),
                    (index.isEven
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary)
                        .withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCard(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final subtleTextColor = isDark ? Colors.white.withOpacity(0.7) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.background.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo with rotating animation
              AnimatedBuilder(
                animation: _rotateAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnimation.value * 0.2,
                    child: Container(
                      padding: EdgeInsets.all(smallPadding),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            isDark ? Colors.white.withOpacity(0.3) : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            isDark ? Colors.white.withOpacity(0.1) : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.4) : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.white.withOpacity(0.2) : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.agriculture,
                        size: AppMeasurements.getResponsiveIconSizeLarge(context),
                        color: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: smallPadding * 1.5),

              // App name with shader
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ).createShader(bounds),
                child: Text(
                  'AgriGuard',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 36),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: smallPadding * 0.5),

              // Tagline
              Text(
                'Protecting Your Crops',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: subtleTextColor,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: smallPadding * 0.5),

              // Subtitle
              Text(
                'Smart Agriculture Solutions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subtleTextColor,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: smallPadding * 2),

              // Progress indicator
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      Container(
                        width: AppMeasurements.getResponsiveSize(context, baseSize: 200),
                        height: AppMeasurements.getResponsiveSize(context, baseSize: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                          color: isDark ? Colors.white.withOpacity(0.3) : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: AppMeasurements.getResponsiveSize(context, baseSize: 200) * _progressAnimation.value,
                            height: AppMeasurements.getResponsiveSize(context, baseSize: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                              gradient: LinearGradient(
                                colors: [
                                  isDark ? Colors.white : Theme.of(context).colorScheme.primary,
                                  isDark ? Colors.white.withOpacity(0.8) : Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: smallPadding),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: subtleTextColor,
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}