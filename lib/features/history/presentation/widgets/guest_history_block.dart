import 'package:flutter/material.dart';
import 'package:agriguard_fyp/core/constants/app_routes.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';

class GuestHistoryBlock extends StatelessWidget {
  final bool isDark;
  final TranslationService t;

  const GuestHistoryBlock({super.key, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
    isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor =
    isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        leading: IconButton(tooltip: 'Back', 
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.get('ui_scan_history'),
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: border),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.secondary.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 28),
            Text(
              t.get('ui_history_requires_an_account'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              t.get('ui_scan_history_is_not_saved_in_guest_mod'),
              style: TextStyle(
                  fontSize: 14, color: captionColor, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  _HistoryBenefit(
                    icon: Icons.history_rounded,
                    title: t.get('ui_all_scans_saved'),
                    subtitle: t.get('ui_every_scan_auto_saved_to_your_account'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _HistoryBenefit(
                    icon: Icons.all_inclusive_rounded,
                    title:
                    t.get('ui_unlimited_scans'),
                    subtitle: t.get('ui_no_5_scan_limit_scan_as_much_as_you_wa'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _HistoryBenefit(
                    icon: Icons.cloud_sync_rounded,
                    title: t.get('ui_cloud_sync'),
                    subtitle: t.get('ui_data_synced_across_all_your_devices'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _HistoryBenefit(
                    icon: Icons.analytics_rounded,
                    title: t.get('ui_analytics_reports'),
                    subtitle: t.get('ui_track_your_crop_health_over_time'),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // pushNamedAndRemoveUntil is intentional here:
                // guest → register clears the stack so the user
                // cannot back-navigate into guest mode.
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.register,
                      (route) => false,
                ),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text(
                  t.get('ui_create_free_account'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.get('ui_already_have_an_account'),
                  style: TextStyle(fontSize: 14, color: captionColor),
                ),
                GestureDetector(
                  // Same intentional stack-clearing as above.
                  onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                        (route) => false,
                  ),
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Private to this file — only used by GuestHistoryBlock.
class _HistoryBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _HistoryBenefit({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
    isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor =
    isDark ? AppColors.darkCaption : AppColors.lightCaption;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor),
              ),
              Text(
                subtitle,
                style: TextStyle(
                    fontSize: 11, color: captionColor, height: 1.3),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded,
            size: 16, color: AppColors.primary),
      ],
    );
  }
}