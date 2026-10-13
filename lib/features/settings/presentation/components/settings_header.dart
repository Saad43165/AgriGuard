import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';

class SettingsHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final double elevation;
  final double topPadding;

  const SettingsHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.elevation = 0,
    this.topPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: bg,
      elevation: 0,
      centerTitle: false,
      leading: showBackButton
          ? IconButton(tooltip: 'Back', 
              icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 22),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (onBackPressed != null) {
                  onBackPressed!();
                } else {
                  Navigator.maybePop(context);
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
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: borderColor),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}
