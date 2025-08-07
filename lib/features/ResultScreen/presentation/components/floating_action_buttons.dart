import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

class FloatingActionButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onShare;

  const FloatingActionButtons({
    super.key,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: onSave,
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: 'Save Report',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.save_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: AppMeasurements.getResponsiveIconSizeMedium(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: onShare,
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: 'Share Results',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.share_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: AppMeasurements.getResponsiveIconSizeMedium(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}