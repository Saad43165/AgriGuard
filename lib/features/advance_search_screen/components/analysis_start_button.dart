import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/translation_service.dart';

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
    final color = selectedOption['color'] as Color;
    final isActive = !isAnalyzing && isAvailable;
    final translation = TranslationService();

    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return GestureDetector(
          onTap: isActive
              ? () {
            HapticFeedback.mediumImpact();
            onPressed();
          }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
                  : LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade500]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: isAnalyzing
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    translation.get('analyzing'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_filled_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    translation.get('start_analysis'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}