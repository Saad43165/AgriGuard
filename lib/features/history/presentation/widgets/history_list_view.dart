import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/severity_indicator.dart';

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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: scans.length,
      itemBuilder: (context, index) {
        final scan = scans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppMeasurements.smallPadding),
          child: GlassCard(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(
                    context,
                    AppRoutes.results,
                    arguments: scan,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
                  child: Row(
                    children: [
                      _buildScanImage(scan, context),
                      const SizedBox(width: AppMeasurements.defaultPadding),
                      _buildScanDetails(scan, context),
                      _buildDeleteButton(index, context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanImage(Map<String, dynamic> scan, BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
      child: scan['imageUrl'] != null
          ? Image.file(
        File(scan['imageUrl'] as String),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(context),
      )
          : _buildErrorImage(context),
    );
  }

  Widget _buildErrorImage(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
      ),
      child: Icon(
        AppIcons.imageError,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  Widget _buildScanDetails(Map<String, dynamic> scan, BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scan['result'],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppMeasurements.extraSmallPadding),
          Text(
            scan['timestamp'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppMeasurements.extraSmallPadding),
          SeverityIndicator(severity: scan['severity']),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(int index, BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.delete_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      onPressed: () => onDelete(index),
    );
  }
}