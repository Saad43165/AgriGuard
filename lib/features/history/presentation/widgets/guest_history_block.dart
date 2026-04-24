import 'package:flutter/material.dart';
import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/widgets/app_themes.dart';
import '../../../../../core/services/translation_service.dart';

class GuestHistoryBlock extends StatelessWidget {
  final bool isDark;
  final TranslationService t;

  const GuestHistoryBlock({super.key, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.isUrdu ? 'اسکین ہسٹری' : 'Scan History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.secondary.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 28),
            Text(
              t.isUrdu ? 'ہسٹری صرف اکاؤنٹ کے لیے' : 'History Requires an Account',
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
              t.isUrdu
                  ? 'مہمان موڈ میں اسکین ہسٹری محفوظ نہیں ہوتی۔ اپنے تمام اسکینز دیکھنے کے لیے مفت اکاؤنٹ بنائیں۔'
                  : 'Scan history is not saved in guest mode. Create a free account to save and view all your scans.',
              style: TextStyle(fontSize: 14, color: captionColor, height: 1.6),
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
                  HistoryBenefit(
                    icon: Icons.history_rounded,
                    title: t.isUrdu ? 'تمام اسکینز محفوظ' : 'All Scans Saved',
                    subtitle: t.isUrdu
                        ? 'ہر اسکین خودکار محفوظ ہوتا ہے'
                        : 'Every scan auto-saved to your account',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  HistoryBenefit(
                    icon: Icons.all_inclusive_rounded,
                    title: t.isUrdu ? 'لامحدود اسکینز' : 'Unlimited Scans',
                    subtitle: t.isUrdu
                        ? '5 کی حد ختم — جتنے چاہیں اسکین کریں'
                        : 'No 5-scan limit — scan as much as you want',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  HistoryBenefit(
                    icon: Icons.cloud_sync_rounded,
                    title: t.isUrdu ? 'کلاؤڈ سنک' : 'Cloud Sync',
                    subtitle: t.isUrdu
                        ? 'تمام ڈیوائسز پر ڈیٹا محفوظ'
                        : 'Data synced across all your devices',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  HistoryBenefit(
                    icon: Icons.analytics_rounded,
                    title: t.isUrdu ? 'تجزیات اور رپورٹس' : 'Analytics & Reports',
                    subtitle: t.isUrdu
                        ? 'اپنی فصلوں کی صحت ٹریک کریں'
                        : 'Track your crop health over time',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.register,
                  (route) => false,
                ),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text(
                  t.isUrdu ? 'مفت اکاؤنٹ بنائیں' : 'Create Free Account',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.isUrdu ? 'پہلے سے اکاؤنٹ ہے؟ ' : 'Already have an account? ',
                  style: TextStyle(fontSize: 14, color: captionColor),
                ),
                GestureDetector(
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

class HistoryBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const HistoryBenefit({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: captionColor, height: 1.3),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
      ],
    );
  }
}
