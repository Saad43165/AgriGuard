import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool useSolidBackground;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final Color? backgroundColor;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.useSolidBackground = false,
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.padding = const EdgeInsets.all(20),
    this.elevation = 20.0,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Calculate background colors
    final Color surfaceColor = backgroundColor ?? colorScheme.surface;
    final Color effectiveBorderColor = borderColor ??
        (isDarkMode ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.4));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: useSolidBackground
            ? surfaceColor.withOpacity(isDarkMode ? 0.95 : 0.98)
            : null,
        gradient: !useSolidBackground
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.05),
          ]
              : [
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.3),
          ],
        )
            : null,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.15),
            blurRadius: elevation,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          if (!useSolidBackground)
            BoxShadow(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.8),
              blurRadius: 2,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Backdrop filter for glass effect (only when not using solid background)
            if (!useSolidBackground)
              BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: blur,
                  sigmaY: blur,
                ),
                child: Container(
                  color: Colors.transparent,
                ),
              ),

            // Content with proper background for readability
            Container(
              padding: padding,
              decoration: useSolidBackground
                  ? null
                  : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(isDarkMode ? 0.05 : 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}