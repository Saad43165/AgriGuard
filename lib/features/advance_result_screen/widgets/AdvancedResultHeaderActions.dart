import 'package:flutter/material.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/app_themes.dart';

class AdvancedResultHeaderActions extends StatelessWidget {
  final bool isUrdu;
  final VoidCallback onShare;
  final VoidCallback onToggleLanguage;
  final String shareTooltip;
  final String languageTooltip;

  const AdvancedResultHeaderActions({
    super.key,
    required this.isUrdu,
    required this.onShare,
    required this.onToggleLanguage,
    required this.shareTooltip,
    required this.languageTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppBarIconButton(
          icon: Icons.share_rounded,
          tooltip: shareTooltip,
          onPressed: onShare,
        ),
        AppBarIconButton(
          icon: Icons.translate_rounded,
          color: isUrdu ? AppColors.secondary : AppColors.primary,
          tooltip: languageTooltip,
          onPressed: onToggleLanguage,
        ),
      ],
    );
  }
}