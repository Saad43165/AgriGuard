import 'package:flutter/material.dart';
import '../models/onboarding_data.dart';
import 'dart:math' as math;

class InteractivePageContent extends StatefulWidget {
  final OnboardingData data;
  final bool isActive;

  const InteractivePageContent({
    super.key,
    required this.data,
    required this.isActive,
  });

  @override
  State<InteractivePageContent> createState() => _InteractivePageContentState();
}

class _InteractivePageContentState extends State<InteractivePageContent>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _featuresController;
  late AnimationController _orbitController;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _featuresController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // FIXED: Separate smooth orbit controller
    _orbitController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    if (widget.isActive) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(InteractivePageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimations();
    }
  }

  void _startAnimations() async {
    _iconController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 300));
    _featuresController.forward(from: 0);
  }

  @override
  void dispose() {
    _iconController.dispose();
    _featuresController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Animated Main Icon - FIXED: No rotation, smooth orbit
                  _buildMainIcon(isDark),

                  const SizedBox(height: 32),

                  // Title and Subtitle
                  _buildTitle(),

                  const SizedBox(height: 10),

                  _buildSubtitle(),

                  const SizedBox(height: 16),

                  // Description
                  _buildDescription(),

                  const SizedBox(height: 20),

                  // Interactive Features - FIXED: Better spacing
                  _buildFeatures(isDark),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainIcon(bool isDark) {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        final scale = Curves.easeOutBack.transform(_iconController.value);

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 180,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main icon container
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Shine effect
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.center,
                              colors: [
                                Colors.white.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Main icon - NO ROTATION
                      Center(
                        child: Icon(
                          widget.data.mainIcon,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Orbiting feature icons - FIXED: Smooth, no distortion
                ..._buildOrbitingIcons(),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildOrbitingIcons() {
    return List.generate(3, (index) {
      return AnimatedBuilder(
        animation: _orbitController,
        builder: (context, child) {
          // FIXED: Smooth continuous rotation
          final angle = (index * 2 * math.pi / 3) + (_orbitController.value * 2 * math.pi);
          final radius = 85.0;
          final x = radius * math.cos(angle);
          final y = radius * math.sin(angle);

          // FIXED: Scale based on main animation only
          final scale = Curves.easeOutBack.transform(_iconController.value);

          return Transform.translate(
            offset: Offset(x, y),
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.data.featureIcons[index],
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildTitle() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: widget.isActive ? 1.0 : 0.0),
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
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ).createShader(bounds),
        child: Text(
          widget.data.title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: widget.isActive ? 1.0 : 0.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          widget.data.subtitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: widget.isActive ? 1.0 : 0.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(
        widget.data.description,
        style: TextStyle(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          height: 1.5,
          letterSpacing: 0.2,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFeatures(bool isDark) {
    return AnimatedBuilder(
      animation: _featuresController,
      builder: (context, child) {
        return Column(
          children: List.generate(widget.data.features.length, (index) {
            final delay = index * 0.15;
            final progress = (_featuresController.value - delay).clamp(0.0, 1.0);

            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 15 * (1 - progress)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.data.features[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}