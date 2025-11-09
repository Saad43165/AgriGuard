import 'package:flutter/material.dart';
import 'history_card_widget.dart';
import 'history_measurements.dart';

/// List view for displaying history cards
class HistoryListView extends StatelessWidget {
  final List<Map<String, dynamic>> scans;
  final Function(int) onDelete;

  const HistoryListView({
    super.key,
    required this.scans,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: scans.length,
      separatorBuilder: (context, index) => const SizedBox(
        height: HistoryMeasurements.cardSpacing,
      ),
      itemBuilder: (context, index) {
        final scan = scans[index];
        return HistoryCardWidget(
          scan: scan,
          index: index,
          onDelete: () => onDelete(index),
        );
      },
    );
  }
}