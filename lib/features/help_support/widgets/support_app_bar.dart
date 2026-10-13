// lib/features/HelpSupport/presentation/widgets/support_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_fyp/core/constants/app_routes.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';

/// Standard AppBar for Help & Support screen.
/// Consistent with the rest of the app.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final double elevation;
  final double topPadding;
  final bool showLanguageToggle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.elevation = 0,
    this.topPadding = 0,
    this.showLanguageToggle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  void _handleBack(BuildContext context) {
    HapticFeedback.lightImpact();
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final translation = Provider.of<TranslationService>(context);

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      leading: showBackButton
          ? IconButton(tooltip: 'Back', 
              icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 22),
              onPressed: () => _handleBack(context),
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
      actions: [
        if (showLanguageToggle)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                translation.toggleLanguage();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      translation.get('ui_en'),
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (actions != null) ...actions!,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: borderColor),
      ),
    );
  }
}
