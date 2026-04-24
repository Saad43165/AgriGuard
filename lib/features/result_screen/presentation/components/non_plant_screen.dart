import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/widgets/app_themes.dart';

// ── Dedicated non-plant screen ────────────────────────────────────────────────
class NonPlantScreen extends StatelessWidget {
  final String? imagePath;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  const NonPlantScreen({super.key, this.imagePath, required this.isDark, required this.onBack, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context);
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: cardBg, shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16,
                      color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)),
              ),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imagePath != null)
                    Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 2)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(File(imagePath!), fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.error.withValues(alpha: 0.08),
                              child: const Icon(Icons.image_not_supported_rounded, size: 48, color: AppColors.error))),
                      ),
                    )
                  else
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.image_not_supported_rounded, size: 52, color: AppColors.error),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    t.isUrdu ? 'پودے کا پتہ نہیں ملا' : 'No Plant Detected',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.isUrdu
                        ? 'یہ تصویر پودے کے پتے کی نہیں لگتی۔ بہتر نتائج کے لیے نیچے دی گئی ہدایات پر عمل کریں۔'
                        : 'This image doesn\'t appear to be a plant leaf. Follow the tips below for better results.',
                    style: TextStyle(fontSize: 14, color: captionColor, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    child: Column(children: [
                      _Tip(icon: Icons.center_focus_strong_rounded,
                          text: t.isUrdu ? 'پتے کو فریم میں بھریں' : 'Fill the frame with a single leaf', isDark: isDark),
                      const SizedBox(height: 10),
                      _Tip(icon: Icons.wb_sunny_rounded,
                          text: t.isUrdu ? 'اچھی روشنی میں تصویر لیں' : 'Use good natural lighting', isDark: isDark),
                      const SizedBox(height: 10),
                      _Tip(icon: Icons.blur_off_rounded,
                          text: t.isUrdu ? 'واضح اور فوکس تصویر لیں' : 'Keep the image sharp and in focus', isDark: isDark),
                      const SizedBox(height: 10),
                      _Tip(icon: Icons.eco_rounded,
                          text: t.isUrdu ? 'صرف پودوں کے پتوں کی تصویر لیں' : 'Only scan plant leaves', isDark: isDark),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(t.isUrdu ? 'دوبارہ اسکین کریں' : 'Scan Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _Tip({required this.icon, required this.text, required this.isDark});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: AppColors.primary, size: 16)),
    const SizedBox(width: 12),
    Expanded(child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkSubtext : const Color(0xFF4A5568)))),
  ]);
}
