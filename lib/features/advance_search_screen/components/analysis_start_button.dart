import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';

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
    final padding = AppMeasurements.getResponsivePadding(context);
    final color = selectedOption['color'] as Color;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAnalyzing || !isAvailable
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isAnalyzing || !isAvailable ? Colors.transparent : color.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAnalyzing || !isAvailable ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isAnalyzing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                else
                  const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAnalyzing
                        ? 'Analyzing...'
                        : 'Start ${selectedOption['title']} Analysis',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}