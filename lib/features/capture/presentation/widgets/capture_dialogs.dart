import 'package:flutter/material.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'package:agriguard_fyp/core/widgets/app_dialog.dart';
import 'package:agriguard_fyp/core/constants/app_routes.dart';

class CaptureRetakeDialog extends StatelessWidget {
  final double confidence;
  final TranslationService t;
  final bool isDark;
  final VoidCallback onRetry;
  final VoidCallback onAdvanced;

  const CaptureRetakeDialog({
    super.key,
    required this.confidence,
    required this.t,
    required this.isDark,
    required this.onRetry,
    required this.onAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    final isVeryLow = confidence < 25.0;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      title: Row(children: [
        Icon(
          isVeryLow ? Icons.help_outline_rounded : Icons.photo_camera_rounded,
          color: AppColors.warning, size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(
          t.isUrdu
              ? (isVeryLow ? 'پودا شناخت نہیں ہوا' : 'بہتر تصویر درکار ہے')
              : (isVeryLow ? 'Plant Not Identified' : 'Better Photo Needed'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        )),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          t.isUrdu
              ? 'اعتماد ${confidence.toStringAsFixed(0)}% ہے — قابل اعتماد نتیجے کے لیے بہت کم ہے۔'
              : 'Confidence is ${confidence.toStringAsFixed(0)}% — too low for a reliable result.',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              t.get('ui_tips_for_better_results'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _tip(t.get('ui_fill_frame_with_a_single_leaf')),
            _tip(t.get('ui_use_good_natural_lighting_2')),
            _tip(t.get('ui_keep_image_sharp_and_in_focus')),
            _tip(t.get('ui_avoid_shadows_on_the_leaf')),
            _tip(t.get('ui_try_advanced_ai_for_better_accuracy')),
          ]),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: onRetry,
          child: Text(
            t.get('ui_try_again'),
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          onPressed: onAdvanced,
          child: Text(
            t.get('ui_advanced_ai'),
            style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _tip(String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('• ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
    ]),
  );
}

class CaptureTop3Dialog extends StatelessWidget {
  final List top3;
  final double confidence;
  final bool isDark;
  final void Function(Map) onSelect;
  final VoidCallback onRetake;

  const CaptureTop3Dialog({
    super.key,
    required this.top3,
    required this.confidence,
    required this.isDark,
    required this.onSelect,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final topPick = top3.isNotEmpty ? top3[0] as Map : <String, dynamic>{};
    final topPlant = topPick['plantName']?.toString() ?? 'this plant';
    final topDisease = topPick['diseaseName']?.toString() ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.help_outline_rounded, color: AppColors.warning, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            topDisease.toLowerCase() == 'healthy'
                ? (isDark ? 'یہ $topPlant صحت مند ہے' : 'This looks like Healthy $topPlant')
                : (isDark ? '$topPlant میں $topDisease' : 'Possible: $topDisease on $topPlant'),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isDark
                ? 'مجھے ${confidence.toStringAsFixed(0)}% یقین ہے۔ کیا یہ درست ہے؟'
                : 'I\'m ${confidence.toStringAsFixed(0)}% confident. Is this correct?',
            style: TextStyle(fontSize: 13,
                color: isDark ? AppColors.darkCaption : AppColors.lightCaption),
            textAlign: TextAlign.center,
          ),
          if (top3.length > 1) ...[
            const SizedBox(height: 16),
            Text(
              isDark ? 'دوسرے نتائج:' : 'Other possibilities:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkCaption : AppColors.lightCaption),
            ),
          ],
          const SizedBox(height: 8),
          ...top3.take(3).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final pred = entry.value as Map;
            final pConf = double.tryParse(pred['confidence']?.toString() ?? '0') ?? 0.0;
            final pPlant = pred['plantName']?.toString() ?? '';
            final pDisease = pred['diseaseName']?.toString() ?? '';
            final isFirst = idx == 0;
            final isHealthy = pDisease.toLowerCase() == 'healthy';

            return GestureDetector(
              onTap: () => onSelect(pred),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isFirst
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : (isDark ? AppColors.darkBg : AppColors.lightBg),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFirst ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: isFirst ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isFirst
                          ? AppColors.primary
                          : (isDark ? AppColors.darkCard : Colors.white),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(
                      '${idx + 1}',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: isFirst ? Colors.white : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
                      ),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pPlant, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: isFirst ? AppColors.primary : (isDark ? AppColors.darkCaption : AppColors.lightCaption))),
                    Text(pDisease, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)),
                  ])),
                  const SizedBox(width: 8),
                  Column( crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${pConf.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                            color: isFirst ? AppColors.primary : (isDark ? AppColors.darkSubtext : AppColors.lightCaption))),
                    if (isHealthy)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('✓',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green)),
                      ),
                  ]),
                ]),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRetake,
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(isDark ? 'دوبارہ تصویر لیں' : 'Retake Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class GuestLimitDialog extends StatelessWidget {
  final TranslationService t;
  const GuestLimitDialog({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: Icon(Icons.block_rounded, color: Theme.of(context).colorScheme.error),
      title: t.get('limit_reached'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(t.get('limit_message')),
        const SizedBox(height: 8),
        Text(t.get('limit_benefit')),
      ]),
      actions: [
        AppDialogActions.secondary(context, label: t.get('cancel'), onPressed: () => Navigator.pop(context)),
        AppDialogActions.primary(context, label: t.get('sign_in_now'), icon: Icons.login_rounded,
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false)),
      ],
    );
  }
}
