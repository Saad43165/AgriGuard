import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blurIntensity;
  final double elevation;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final bool showBorder;
  final double borderWidth;
  final GlassType glassType;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 16.0,
    this.blurIntensity = 12.0,
    this.elevation = 8.0,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.showBorder = true,
    this.borderWidth = 1.0,
    this.glassType = GlassType.auto,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final effectiveGlassType = glassType == GlassType.auto
        ? (isDarkMode ? GlassType.dark : GlassType.light)
        : glassType;

    final glassColors = _getGlassColors(effectiveGlassType, colorScheme, isDarkMode);
    final borderColor = _getBorderColor(effectiveGlassType, colorScheme, isDarkMode);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: gradientBegin,
                  end: gradientEnd,
                  colors: glassColors.backgroundGradient,
                ),
                border: showBorder
                    ? Border.all(color: borderColor, width: borderWidth)
                    : null,
                // Optional: Add subtle shadow for depth in light mode
                boxShadow: isDarkMode
                    ? null
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: elevation,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  GlassColors _getGlassColors(GlassType type, ColorScheme colorScheme, bool isDarkMode) {
    switch (type) {
      case GlassType.light:
        return GlassColors(
          backgroundGradient: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.1),
          ],
        );
      case GlassType.dark:
        return GlassColors(
          backgroundGradient: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        );
      case GlassType.primary:
        return GlassColors(
          backgroundGradient: [
            colorScheme.primary.withOpacity(0.3),
            colorScheme.primary.withOpacity(0.2),
            colorScheme.primary.withOpacity(0.08),
          ],
        );
      case GlassType.surface:
        return GlassColors(
          backgroundGradient: [
            colorScheme.surface.withOpacity(isDarkMode ? 0.2 : 0.4),
            colorScheme.surface.withOpacity(isDarkMode ? 0.12 : 0.25),
            colorScheme.surface.withOpacity(isDarkMode ? 0.05 : 0.1),
          ],
        );
      default:
        return _getGlassColors(
            isDarkMode ? GlassType.dark : GlassType.light, colorScheme, isDarkMode);
    }
  }

  // FIXED: Border now visible in light mode
  Color _getBorderColor(GlassType type, ColorScheme colorScheme, bool isDarkMode) {
    if (isDarkMode) {
      // Dark mode: white/opaque borders
      return switch (type) {
        GlassType.light => Colors.white.withOpacity(0.4),
        GlassType.dark => Colors.white.withOpacity(0.25),
        GlassType.primary => colorScheme.primary.withOpacity(0.5),
        GlassType.surface => Colors.white.withOpacity(0.3),
        _ => Colors.white.withOpacity(0.25),
      };
    } else {
      // LIGHT MODE: Use dark/primary border for visibility
      return switch (type) {
        GlassType.light => Colors.black.withOpacity(0.2), // ← Visible!
        GlassType.dark => colorScheme.primary.withOpacity(0.4),
        GlassType.primary => colorScheme.primary.withOpacity(0.5),
        GlassType.surface => Colors.black.withOpacity(0.25),
        _ => Colors.black.withOpacity(0.2),
      };
    }
  }
}

class GlassColors {
  final List<Color> backgroundGradient;
  const GlassColors({required this.backgroundGradient});
}

enum GlassType { auto, light, dark, primary, surface }