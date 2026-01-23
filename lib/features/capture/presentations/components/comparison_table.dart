import 'package:flutter/material.dart';

class ComparisonTable extends StatelessWidget {
  const ComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final apiColor = const Color(0xFF6A11CB);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Method Comparison',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildComparisonTable(context, apiColor, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context, Color apiColor, bool isDarkMode) {
    final comparisons = [
      {'feature': 'Internet Required', 'tflite': 'No', 'api': 'Yes'},
      {'feature': 'Processing Speed', 'tflite': 'Instant', 'api': '10-30 seconds'},
      {'feature': 'Plant Database', 'tflite': '12 species', 'api': '50,000+ species'},
      {'feature': 'Privacy Level', 'tflite': '100% Private', 'api': 'Cloud Processing'},
      {'feature': 'Best For', 'tflite': 'Quick Checks', 'api': 'Detailed Analysis'},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
      },
      children: [
        _buildTableHeader(context, apiColor, isDarkMode),
        ...comparisons.map((comp) => _buildTableRow(context, comp, apiColor, isDarkMode)),
      ],
    );
  }

  TableRow _buildTableHeader(BuildContext context, Color apiColor, bool isDarkMode) {
    final tfliteColor = const Color(0xFF00B4DB);

    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Feature',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              'On-Device',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : tfliteColor,
                fontSize: 14,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              'Cloud AI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : apiColor,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(BuildContext context, Map<String, String> comp, Color apiColor, bool isDarkMode) {
    final tfliteColor = const Color(0xFF00B4DB);
    final tfliteColorLight = const Color(0xFF00B4DB);
    final apiColorLight = const Color(0xFF6A11CB);

    final tfliteTextColor = isDarkMode ? Colors.white : tfliteColorLight;
    final apiTextColor = isDarkMode ? Colors.white : apiColorLight;

    final tfliteBgColor = isDarkMode ? Colors.white.withOpacity(0.1) : tfliteColorLight.withOpacity(0.15);
    final apiBgColor = isDarkMode ? Colors.white.withOpacity(0.1) : apiColorLight.withOpacity(0.15);

    final tfliteBorderColor = isDarkMode ? Colors.white.withOpacity(0.3) : tfliteColorLight.withOpacity(0.3);
    final apiBorderColor = isDarkMode ? Colors.white.withOpacity(0.3) : apiColorLight.withOpacity(0.3);

    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            comp['feature']!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tfliteBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: tfliteBorderColor,
                  width: 1,
                ),
              ),
              child: Text(
                comp['tflite']!,
                style: TextStyle(
                  color: tfliteTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: apiBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: apiBorderColor,
                  width: 1,
                ),
              ),
              child: Text(
                comp['api']!,
                style: TextStyle(
                  color: apiTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}