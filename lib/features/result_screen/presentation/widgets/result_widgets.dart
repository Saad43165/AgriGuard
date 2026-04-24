import 'package:flutter/material.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';

class ResultCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const ResultCircleBtn({required this.icon, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

class ResultChip extends StatelessWidget {
  final String icon, label;
  final bool isDark;
  const ResultChip({required this.icon, required this.label, required this.isDark, super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkBg : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE8E8E8)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkSubtext : const Color(0xFF4A5568))),
    ]),
  );
}

class ResultAlertRow extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final bool isDark;
  const ResultAlertRow({required this.icon, required this.message, required this.color, required this.isDark, super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: TextStyle(fontSize: 12,
          color: isDark ? AppColors.darkSubtext : const Color(0xFF4A5568), height: 1.4))),
    ]),
  );
}

class ResultSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  const ResultSectionHeader({required this.icon, required this.title, required this.isDark, super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.primary, size: 16),
    const SizedBox(width: 8),
    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E))),
  ]);
}
