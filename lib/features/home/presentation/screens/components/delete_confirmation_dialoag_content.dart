// lib/features/scan_history/presentation/components/delete_confirmation_dialog_content.dart
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/glass_card.dart';

class DeleteConfirmationDialogContent extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const DeleteConfirmationDialogContent({
    super.key,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_rounded,
              color: Theme.of(context).colorScheme.error,
              size: AppMeasurements.getResponsiveIconSizeLarge(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Scan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete this scan? This action cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: onCancel ?? () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    onConfirm();
                  },
                  child: Text(
                    'Delete',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}