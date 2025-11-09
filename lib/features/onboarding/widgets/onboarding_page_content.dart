import 'package:flutter/material.dart';
import '../../../core/constants/app_measurements.dart';
import '../models/onboarding_data.dart';

class OnboardingPageContent extends StatefulWidget {
  final OnboardingData data;
  const OnboardingPageContent({super.key, required this.data});

  @override
  State<OnboardingPageContent> createState() => _OnboardingPageContentState();
}

class _OnboardingPageContentState extends State<OnboardingPageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _iconRotationAnimation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _iconController.forward();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: screenHeight * 0.7),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppMeasurements.getResponsivePadding(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: AppMeasurements.getResponsiveSize(context, baseSize: 40)),
              _buildProfessionalIcon(context, colorScheme),
              SizedBox(height: AppMeasurements.getResponsiveSize(context, baseSize: 48)),
              _buildTitle(context, theme, colorScheme),
              SizedBox(height: AppMeasurements.smallPadding),
              _buildDescription(context, theme, colorScheme),
              SizedBox(height: AppMeasurements.getResponsiveSize(context, baseSize: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalIcon(BuildContext context, ColorScheme colorScheme) {
    final baseSize = AppMeasurements.getResponsiveIconSizeLarge(context);
    final containerSize = baseSize * 1.4;
    final outerRingSize = containerSize * 1.05;
    final iconFontSize = containerSize * 0.5;

    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        final double glowValue = _glowAnimation.value;
        final double scale = _iconScaleAnimation.value * _pulseAnimation.value;
        final double iconScale = _iconScaleAnimation.value;
        final double rotation = _iconRotationAnimation.value;

        // Pre-calculate animated opacities
        final double glowOpacity = glowValue * 0.15;
        final double outerRingOpacity = glowValue;
        final double shineOpacity = glowValue * 0.08;
        final double accentOpacity1 = glowValue * 0.7;
        final double accentOpacity2 = glowValue * 0.5;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // === Outer Glow (no Opacity widget) ===
            Container(
              width: outerRingSize * 1.3,
              height: outerRingSize * 1.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(glowOpacity * 1.33), // 0.2 / 0.15
                    blurRadius: 30,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),

            // === Outer Ring with Animated Gradient ===
            Transform.scale(
              scale: scale,
              child: Container(
                width: outerRingSize,
                height: outerRingSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.1 * outerRingOpacity),
                      colorScheme.secondary.withOpacity(0.008 * outerRingOpacity),
                    ],
                  ),
                ),
              ),
            ),

            // === Main Icon Container ===
            Transform.scale(
              scale: iconScale,
              child: Transform.rotate(
                angle: rotation,
                child: Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.15),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Shine overlay (animated)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.center,
                              colors: [
                                Colors.white.withOpacity(shineOpacity),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Icon with gradient
                      Center(
                        child: _buildIconContent(context, colorScheme, iconFontSize),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // === Minimal Accent Dots (animated opacity in color) ===
            ..._buildMinimalAccents(
              context,
              colorScheme,
              containerSize,
              accentOpacity1,
              accentOpacity2,
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildMinimalAccents(
      BuildContext context,
      ColorScheme colorScheme,
      double containerSize,
      double accentOpacity1,
      double accentOpacity2,
      ) {
    return [
      // Top accent dot
      Positioned(
        top: containerSize * -0.08,
        right: containerSize * 0.2,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(accentOpacity1),
                colorScheme.secondary.withOpacity(accentOpacity1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(accentOpacity1 * 0.57), // 0.4 / 0.7
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
      // Bottom accent dot
      Positioned(
        bottom: containerSize * 0.05,
        left: containerSize * -0.05,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.secondary.withOpacity(accentOpacity2),
            boxShadow: [
              BoxShadow(
                color: colorScheme.secondary.withOpacity(accentOpacity2 * 0.6), // 0.3 / 0.5
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildIconContent(BuildContext context, ColorScheme colorScheme, double iconFontSize) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colorScheme.primary, colorScheme.secondary],
      ).createShader(bounds),
      child: Text(
        widget.data.icon,
        style: TextStyle(
          fontSize: iconFontSize,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          height:1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(
        widget.data.title,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
          height: 1.2,
          fontSize: AppMeasurements.getResponsiveFontSize(
            context,
            baseSize: 28,
          ),
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    );
  }

  Widget _buildDescription(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(
        widget.data.description,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.7),
          height: 1.6,
          fontSize: AppMeasurements.getResponsiveFontSize(
            context,
            baseSize: 16,
          ),
          letterSpacing: 0.2,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}