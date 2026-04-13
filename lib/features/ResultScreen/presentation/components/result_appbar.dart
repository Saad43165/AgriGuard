import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/widgets/app_themes.dart';
import '../../../../../core/services/translation_service.dart';

class AppBarContent extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final double elevation;
  final double topPadding;
  final Widget? leading;

  const AppBarContent({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.elevation = 0,
    this.topPadding = 0,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final translation = Provider.of<TranslationService>(context);
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Back button
                if (showBackButton)
                  _IconBtn(
                    icon: Icons.arrow_back_rounded,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onBackPressed != null ? onBackPressed!() : Navigator.maybePop(context);
                    },
                  )
                else
                  const SizedBox(width: 40),

                const SizedBox(width: 8),

                // Title
                Expanded(
                  child: Text(
                    translation.get(title),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                // Language toggle
                _LangBtn(isDark: isDark, translation: translation),

                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Icon(icon, size: 20,
          color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final bool isDark;
  final TranslationService translation;
  const _LangBtn({required this.isDark, required this.translation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); translation.toggleLanguage(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              translation.isUrdu ? 'اردو' : 'EN',
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800,
                color: AppColors.primary, letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
