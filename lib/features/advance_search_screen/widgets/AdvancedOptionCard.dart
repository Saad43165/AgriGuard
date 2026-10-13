import 'package:flutter/material.dart';
import '../../../core/widgets/app_themes.dart';
import '../models/advanced_option.dart';

class AdvancedOptionCard extends StatelessWidget {
  final AdvancedOption option;
  final bool isSelected;
  final bool isAvailable;
  final bool isDark;
  final int index;
  final VoidCallback? onTap;

  const AdvancedOptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isAvailable,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  static const _tagColors = [
    AppColors.blue,
    AppColors.emerald,
    AppColors.secondary,
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final accentColor = _tagColors[index];

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 96), // helps avoid overflow
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(option.icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 10),

            /// KEY FIX: make text area flexible + ellipsis
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isAvailable ? textColor : captionColor,
                          ),
                        ),
                      ),
                      if (!isAvailable)
                        Container(
                          margin: const EdgeInsetsDirectional.only(start: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Offline',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.subtitle,
                    maxLines: 2, // important for Urdu
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: captionColor, height: 1.25),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          option.tag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                      Text(
                        option.duration,
                        style: TextStyle(fontSize: 10, color: captionColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : captionColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}