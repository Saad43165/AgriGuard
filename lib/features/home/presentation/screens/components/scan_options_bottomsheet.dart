import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'glass_card.dart';

class ScanOptionsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> scan;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const ScanOptionsBottomSheet({
    super.key,
    required this.scan,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.visibility_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'View Details',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/results', arguments: scan);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.share_rounded,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              'Share Results',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onShare();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete Scan',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}