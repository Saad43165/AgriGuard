import 'package:flutter/material.dart';
import 'app_themes.dart';

/// Botanical-style dialog — clean white card, no gradients
class AppDialog extends StatelessWidget {
  final Widget? icon;
  final String? title;
  final Widget? titleWidget;
  final Widget? content;
  final List<Widget> actions;
  final bool showClose;

  const AppDialog({
    super.key,
    this.icon,
    this.title,
    this.titleWidget,
    this.content,
    this.actions = const [],
    this.showClose = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : const Color(0xFFE8E8E8);
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final subColor = isDark ? AppColors.darkCaption : const Color(0xFF718096);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: icon),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: titleWidget ?? Text(
                      title ?? '',
                      style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: textColor, letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (showClose)
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Icon(Icons.close_rounded, size: 20, color: subColor),
                    ),
                ],
              ),

              // Content
              if (content != null) ...[
                const SizedBox(height: 12),
                DefaultTextStyle(
                  style: TextStyle(fontSize: 14, color: subColor, height: 1.5),
                  child: content!,
                ),
              ],

              // Actions
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions.map((w) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: w,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppDialogActions {
  static Widget primary(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: icon != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16), const SizedBox(width: 6), Text(label)])
          : Text(label),
    );
  }

  static Widget secondary(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE8E8E8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      ),
      child: Text(label),
    );
  }
}
