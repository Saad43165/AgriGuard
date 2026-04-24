import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_themes.dart';

class HistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const HistoryAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
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
        child: Divider(height: 1, thickness: 1, color: borderColor),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}