import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surface.withOpacity(isDark ? 0.92 : 1.0),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.30 : 0.12),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: theme.colorScheme.primary.withOpacity(0.12),
                          ),
                          child: Center(child: icon),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: titleWidget ??
                            Text(
                              title ?? '',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.1,
                              ),
                            ),
                      ),
                      if (showClose)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                    ],
                  ),
                  if (content != null) ...[
                    const SizedBox(height: 12),
                    DefaultTextStyle(
                      style: theme.textTheme.bodyMedium!.copyWith(
                        height: 1.35,
                        color: theme.colorScheme.onSurface.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                      child: content!,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (actions.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions
                          .map((w) => Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: w,
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
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
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
      ),
    );
  }

  static Widget secondary(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}

