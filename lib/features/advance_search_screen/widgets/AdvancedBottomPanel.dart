import 'package:flutter/material.dart';
import '../../../core/widgets/app_themes.dart';
import '../models/advanced_option.dart';
import 'AdvancedOptionCard.dart';

class AdvancedBottomPanel extends StatelessWidget {
  final bool isDark;
  final bool isCheckingApis;
  final bool isAnalyzing;
  final int selectedIndex;
  final List<AdvancedOption> options;
  final bool Function(int) isOptionAvailable;
  final ValueChanged<int> onSelectOption;
  final VoidCallback onAnalyze;
  final String analyzeLabel;

  const AdvancedBottomPanel({
    super.key,
    required this.isDark,
    required this.isCheckingApis,
    required this.isAnalyzing,
    required this.selectedIndex,
    required this.options,
    required this.isOptionAvailable,
    required this.onSelectOption,
    required this.onAnalyze,
    required this.analyzeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    return Container(
      color: cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Scrollable cards area
          Expanded(
            child: isCheckingApis
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        ...List.generate(
                          options.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AdvancedOptionCard(
                              option: options[i],
                              isSelected: selectedIndex == i,
                              isAvailable: isOptionAvailable(i),
                              isDark: isDark,
                              index: i,
                              onTap: isOptionAvailable(i) && !isAnalyzing
                                  ? () => onSelectOption(i)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
          ),

          // Pinned scan button at the bottom
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isAnalyzing ? null : onAnalyze,
                child: Text(analyzeLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
