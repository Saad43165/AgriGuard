// lib/core/widgets/app_bar.dart
//
// Shared AppBar widget — single source of truth for all screens.
// Ensures consistent styling across the entire app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_themes.dart';

/// Standard AppBar used by all secondary screens (not home).
/// Provides consistent back button, title, divider, and action buttons.
class AgriAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  const AgriAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.bottom,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0) + 1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 22),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (onBack != null) {
                  onBack!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: -0.3,
        ),
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(
            1 + (bottom?.preferredSize.height ?? 0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bottom != null) bottom!,
            Divider(height: 1, thickness: 1, color: borderColor),
          ],
        ),
      ),
    );
  }
}

/// Standard icon action button for AppBar — consistent size and style.
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;
  final String? tooltip;

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? AppColors.primary;

    return IconButton(
      icon: Icon(icon, color: iconColor, size: 22),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      tooltip: tooltip,
    );
  }
}
