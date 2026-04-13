import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/translation_service.dart';

class SourceCard extends StatelessWidget {
  final ImageSource source;
  final IconData icon;
  final String titleKey;
  final String descKey;
  final List<String> tips;
  final List<Color> gradient;
  final bool isLoading;
  final VoidCallback? onTap;

  const SourceCard({
    super.key,
    required this.source,
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.tips,
    required this.gradient,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final translation = TranslationService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = gradient[0];

    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading
                ? null
                : () {
              HapticFeedback.mediumImpact();
              onTap?.call();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                // Better contrast for light mode
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                    effectiveColor.withValues(alpha: 0.2),
                    gradient[1].withValues(alpha: 0.15),
                  ]
                      : [
                    Colors.white,
                    effectiveColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? effectiveColor.withValues(alpha: 0.5)
                      : effectiveColor.withValues(alpha: 0.6),
                  width: 2,
                ),
                // Stronger shadow for light mode
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? effectiveColor.withValues(alpha: 0.25)
                        : effectiveColor.withValues(alpha: 0.3),
                    blurRadius: isDark ? 12 : 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, translation, effectiveColor, isDark),
                  const SizedBox(height: 8),
                  _buildTipsSection(context, translation, effectiveColor, isDark),
                  const SizedBox(height: 10),
                  _buildSelectButton(context, translation, effectiveColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, TranslationService translation,
      Color effectiveColor, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translation.get(titleKey),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                translation.get(descKey),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.65),
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: effectiveColor,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildTipsSection(BuildContext context, TranslationService translation,
      Color effectiveColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        // Better visibility in light mode
        color: isDark
            ? effectiveColor.withValues(alpha: 0.15)
            : effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? effectiveColor.withValues(alpha: 0.3)
              : effectiveColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, size: 13, color: effectiveColor),
              const SizedBox(width: 5),
              Text(
                translation.get('source_tips'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? effectiveColor : effectiveColor.withValues(alpha: 0.9),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.circle,
                    size: 4,
                    color: isDark
                        ? effectiveColor.withValues(alpha: 0.7)
                        : effectiveColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.75)
                          : Colors.black.withValues(alpha: 0.75),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSelectButton(
      BuildContext context, TranslationService translation, Color effectiveColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            source == ImageSource.camera
                ? Icons.camera_alt_rounded
                : Icons.photo_library_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isLoading
                ? translation.get('source_loading').toUpperCase()
                : 'SELECT SOURCE',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }
}