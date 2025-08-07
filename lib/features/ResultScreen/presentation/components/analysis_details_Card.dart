import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../Profile/presentation/Components/glass_card.dart';
import 'section_header.dart';
import 'detail_row.dart';

class AnalysisDetailsCard extends StatelessWidget {
  final Map<String, dynamic> scanData;

  const AnalysisDetailsCard({super.key, required this.scanData});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Analysis Details',
          icon: Icons.analytics_rounded,
        ),
        const SizedBox(height: AppMeasurements.smallPadding),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
            child: Column(
              children: [
                DetailRow(
                  label: 'Confidence Level',
                  value: scanData['confidence']?.toString() ?? '85%',
                  icon: Icons.assessment_rounded,
                ),
                const SizedBox(height: AppMeasurements.smallPadding),
                DetailRow(
                  label: 'Detection Date',
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