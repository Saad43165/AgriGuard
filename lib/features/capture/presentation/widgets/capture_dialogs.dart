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
              t.isUrdu ? '📸 بہتر نتائج کے لیے:' : '📸 Tips for better results:',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _tip(t.isUrdu ? 'پتے کو فریم میں بھریں' : 'Fill frame with a single leaf'),
            _tip(t.isUrdu ? 'اچھی قدرتی روشنی استعمال کریں' : 'Use good natural lighting'),
            _tip(t.isUrdu ? 'تصویر واضح اور فوکس میں ہو' : 'Keep image sharp and in focus'),
            _tip(t.isUrdu ? 'پتے پر سائے سے بچیں' : 'Avoid shadows on the leaf'),
            _tip(t.isUrdu ? 'ایڈوانسڈ AI آزمائیں' : 'Try Advanced AI for better accuracy'),
          ]),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: onRetry,
          child: Text(
            t.isUrdu ? 'دوبارہ کوشش کریں' : 'Try Again',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          onPressed: onAdvanced,
          child: Text(
            t.isUrdu ? 'ایڈوانسڈ AI' : 'Advanced AI',
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      title: Row(children: [
        const Icon(Icons.help_outline_rounded, color: AppColors.warning, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(
          "I'm ${confidence.toStringAsFixed(0)}% sure",
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Which one looks correct?',
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkCaption : AppColors.lightCaption)),
        const SizedBox(height: 12),
        ...top3.asMap().entries.map((entry) {
          final pred = entry.value as Map;
          final pConf = double.tryParse(pred['confidence']?.toString() ?? '0') ?? 0.0;
          final pPlant = pred['plantName']?.toString() ?? '';
          final pDisease = pred['diseaseName']?.toString() ?? '';
          return GestureDetector(
            onTap: () => onSelect(pred),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(pPlant, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  Text(pDisease, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text('${pConf.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
              ]),
            ),
          );
        }),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: onRetake,
          icon: const Icon(Icons.camera_alt_rounded, size: 16),
          label: const Text('Retake Photo'),
          style: TextButton.styleFrom(foregroundColor: AppColors.lightCaption),
        ),
      ]),
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
