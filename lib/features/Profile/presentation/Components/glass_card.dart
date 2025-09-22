import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool useSolidBackground;
  final double? borderRadius;
  final double? blur;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? backgroundColor;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.useSolidBackground = false,
    this.borderRadius,
    this.blur,
    this.padding,
    this.elevation,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        color: useSolidBackground
            ? backgroundColor ?? Theme.of(context).colorScheme.surface.withOpacity(isDarkMode ? 0.95 : 0.98)
            : null,
        gradient: !useSolidBackground
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ]
              : [
            Colors.white.withOpacity(0.7),
            Colors.white.withOpacity(0.3),
          ],
        )
            : null,
        border: Border.all(
          color: borderColor ??
              (isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.4)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: elevation ?? 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          if (!useSolidBackground)
            BoxShadow(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.6),
              blurRadius: 1,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        child: Stack(
          children: [
            // Backdrop filter for glass effect
            if (!useSolidBackground)
              BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: blur ?? 10,
                  sigmaY: blur ?? 10,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
              ),

            // Content
            Container(
              padding: padding ?? const EdgeInsets.all(20),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}