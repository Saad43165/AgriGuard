import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/widgets/app_themes.dart';

class HistoryAppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const HistoryAppBarAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}