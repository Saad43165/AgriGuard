import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_themes.dart';

class HistoryStatsCard extends StatelessWidget {
  final int totalScans;
  final int onDeviceCount;
  final int advancedCount;
  final bool isLoading;

  const HistoryStatsCard({
    super.key,
    required this.totalScans,
    required this.onDeviceCount,
    required this.advancedCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final textSub = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Scans', style: TextStyle(fontSize: 13, color: textSub, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    isLoading ? '--' : '$totalScans',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Stat(icon: Icons.phone_android_rounded, label: 'On-Device', count: onDeviceCount, color: AppColors.info, isLoading: isLoading, textSub: textSub)),
              Container(width: 1, height: 48, color: borderColor),
              Expanded(child: _Stat(icon: Icons.cloud_rounded, label: 'Advanced AI', count: advancedCount, color: AppColors.secondary, isLoading: isLoading, textSub: textSub)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool isLoading;
  final Color textSub;

  const _Stat({required this.icon, required this.label, required this.count,
    required this.color, required this.isLoading, required this.textSub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(isLoading ? '--' : '$count',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: textSub, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
