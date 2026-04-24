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

    return Expanded(
      flex: 58,
      child: Container(
        color: cardBg,
        padding: const EdgeInsets.all(16),
        child: isCheckingApis
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
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
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isAnalyzing ? null : onAnalyze,
                      child: Text(analyzeLabel),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}