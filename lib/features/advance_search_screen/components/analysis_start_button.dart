import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/widgets/app_themes.dart';

class AnalysisStartButton extends StatelessWidget {
  final bool isAnalyzing;
  final Map<String, dynamic> selectedOption;
  final bool isAvailable;
  final VoidCallback onPressed;

  const AnalysisStartButton({
    super.key,
    required this.isAnalyzing,
    required this.selectedOption,
    required this.isAvailable,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = !isAnalyzing && isAvailable;
    final translation = TranslationService();

    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: isActive ? () { HapticFeedback.mediumImpact(); onPressed(); } : null,
            icon: isAnalyzing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.play_circle_filled_rounded, size: 20),
            label: Text(
              isAnalyzing ? translation.get('analyzing') : translation.get('start_analysis'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
          ),
        );
      },
    );
  }
}