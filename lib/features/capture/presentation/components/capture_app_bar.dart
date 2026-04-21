import 'package:flutter/material.dart';
import '../../../../core/services/translation_service.dart';

class CaptureAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentStep;
  final bool isProcessing;
  final String appBarTitle;
  final VoidCallback? onBackPressed;
  final VoidCallback? onInfoPressed;

  const CaptureAppBar({
    super.key,
    required this.currentStep,
    required this.isProcessing,
    required this.appBarTitle,
    this.onBackPressed,
    this.onInfoPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final translation = TranslationService();

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 70,
      leading: currentStep > 0 && !isProcessing
          ? Padding(
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBackPressed,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      )
          : null,
      title: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ).createShader(bounds),
        child: Text(
          _getTitle(), // Always English
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        // Language Toggle Button
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
          child: AnimatedBuilder(
            animation: translation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => translation.toggleLanguage(),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language_rounded,
                            size: 18,
                            color: isDark
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            translation.isUrdu ? 'EN' : 'اردو',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Info Button (only on welcome screen)
        if (currentStep == 0 && onInfoPressed != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 12, top: 8, bottom: 8),
            child: Container(
              width: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onInfoPressed,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 22,
                      color: isDark
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          )
        else if (currentStep == 0)
          const SizedBox(width: 12), // Balanced spacing
      ],
    );
  }

  // Always return English titles
  String _getTitle() {
    switch (currentStep) {
      case 0:
        return 'AGRIGUARD';
      case 1:
        return 'Analysis Method';
      case 2:
        return 'Image Source';
      case 3:
        return 'Analyzing...';
      default:
        return 'AGRIGUARD';
    }
  }
}