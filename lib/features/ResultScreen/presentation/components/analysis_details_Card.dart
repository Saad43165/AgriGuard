import 'package:flutter/material.dart';
import 'section_header.dart';
import 'detail_row.dart';

class AnalysisDetailsCard extends StatelessWidget {
  final Map<String, dynamic> scanData;

  const AnalysisDetailsCard({super.key, required this.scanData});

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Analysis Details',
          icon: Icons.analytics_rounded,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface.withOpacity(0.5)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DetailRow(
                  label: 'Confidence Level',
                  value: scanData['confidence']?.toString() ?? '85%',
                  icon: Icons.assessment_rounded,
                ),
                const SizedBox(height: 16),
                DetailRow(
                  label: 'Scan Date',
                  value: scanData['timestamp'] != null
                      ? _formatDate(DateTime.parse(scanData['timestamp']))
                      : _formatDate(DateTime.now()),
                  icon: Icons.calendar_today_rounded,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}