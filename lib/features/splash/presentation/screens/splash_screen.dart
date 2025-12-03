import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn; // Add this parameter

  const SplashScreen({super.key, required this.isLoggedIn}); // Update constructor

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _orbController;
  late AnimationController _shimmerController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _orbAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    _navigateToNext();
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _logoRotateAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Orb animation
    _orbController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _orbAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );

    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _logoController.forward();

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        _textController.forward();

        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          _progressController.forward();
        }
      }
    }
  }


  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      if (widget.isLoggedIn) {
        // User is logged in, go directly to home
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        // User is not logged in, show onboarding
        Navigator.pushReplacementNamed(context, AppRoutes.onboard);
      }
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateStatusBar();
  }

  void _updateStatusBar() {
    final brightness = Theme.of(context).brightness;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _orbController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.8),
              colorScheme.surface,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background orbs
            ...List.generate(5, (index) => _buildBackgroundOrb(index, screenWidth, screenHeight, colorScheme)),

            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Logo section
                    _buildLogoSection(context, colorScheme),

                    SizedBox(height: AppMeasurements.getResponsiveSize(context, baseSize: 40)),

                    // Text section
                    _buildTextSection(context, colorScheme),

                    const Spacer(flex: 2),

                    // Progress indicator
                    _buildProgressIndicator(context, colorScheme),

                    SizedBox(height: AppMeasurements.getResponsiveSize(context, baseSize: 60)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundOrb(int index, double screenWidth, double screenHeight, ColorScheme colorScheme) {
    final positions = [
      {'top': screenHeight * 0.1, 'left': screenWidth * 0.1},
      {'top': screenHeight * 0.2, 'right': screenWidth * 0.1},
      {'top': screenHeight * 0.6, 'left': screenWidth * 0.05},
      {'top': screenHeight * 0.7, 'right': screenWidth * 0.15},
      {'top': screenHeight * 0.4, 'left': screenWidth * 0.5},
    ];

    return AnimatedBuilder(
      animation: _orbAnimation,
      builder: (context, child) {
        return Positioned(
          top: positions[index]['top'],
          left: positions[index]['left'],
          right: positions[index]['right'],
          child: Transform.scale(
            scale: _orbAnimation.value,
            child: Container(
              width: 100 + (index * 40.0),
              height: 100 + (index * 40.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (index % 2 == 0 ? colorScheme.primary : colorScheme.secondary)
                        .withOpacity(0.06),
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

  Widget _buildLogoSection(BuildContext context, ColorScheme colorScheme) {
    final iconSize = AppMeasurements.getResponsiveIconSizeLarge(context) * 1.5;

    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoFadeAnimation.value,
          child: Transform.scale(
            scale: _logoScaleAnimation.value,
            child: Transform.rotate(
              angle: _logoRotateAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: iconSize * 1.4,
                    height: iconSize * 1.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Middle ring
                  Container(
                    width: iconSize * 1.15,
                    height: iconSize * 1.15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withOpacity(0.15),
                          colorScheme.secondary.withOpacity(0.15),
                        ],
                      ),
                    ),
                  ),

                  // Main logo container
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surface,
                          colorScheme.surface.withOpacity(0.9),
                        ],
                      ),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Shimmer effect
                        AnimatedBuilder(
                          animation: _shimmerAnimation,
                          builder: (context, child) {
                            return ClipOval(
                              child: ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    begin: Alignment(_shimmerAnimation.value - 1, 0),
                                    end: Alignment(_shimmerAnimation.value, 0),
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.1),
                                      Colors.transparent,
                                    ],
                                  ).createShader(bounds);
                                },
                                child: Container(color: Colors.white),
                              ),
                            );
                          },
                        ),

                        // Icon
                        Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ).createShader(bounds),
                            child: Icon(
                              Icons.eco_rounded,
                              size: iconSize * 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextSection(BuildContext context, ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _textFadeAnimation,
      child: SlideTransition(
        position: _textSlideAnimation,
        child: Column(
          children: [
            // App name
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ).createShader(bounds),
              child: Text(
                'AgriGuard',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 42,
                  ),
                  letterSpacing: -1,
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: AppMeasurements.getResponsiveExtraSmallPadding(context)),

            // Tagline
            Text(
              'Protecting Your Crops',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: 18,
                ),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),

            SizedBox(height: AppMeasurements.getResponsiveExtraSmallPadding(context) / 2),

            // Subtitle with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.agriculture_outlined,
                  size: AppMeasurements.getResponsiveIconSizeSmall(context),
                  color: colorScheme.primary.withOpacity(0.7),
                ),
                SizedBox(width: AppMeasurements.extraSmallPadding / 2),
                Text(
                  'Smart Agriculture Solutions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 14,
                    ),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Progress bar
            Container(
              width: AppMeasurements.getResponsiveSize(context, baseSize: 200),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: colorScheme.primary.withOpacity(0.2),
              ),
              child: Stack(
                children: [
                  // Progress fill
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: AppMeasurements.getResponsiveSize(context, baseSize: 200) *
                          _progressAnimation.value,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppMeasurements.smallPadding),

            // Loading text
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: 12,
                ),
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}