import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../Profile/presentation/Components/glass_card.dart';
import 'delete_confirmation_dialoag_content.dart';

class AllScansDialogContent extends StatelessWidget {
  final List<Map<String, dynamic>> recentScans;
  final Function(String) onDeleteScan;
  final Function(Map<String, dynamic>) onShowOptions;

  const AllScansDialogContent({
    super.key,
    required this.recentScans,
    required this.onDeleteScan,
    required this.onShowOptions,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'All Recent Scans',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: recentScans.length,
              itemBuilder: (context, index) {
                final scan = recentScans[index];
                return Dismissible(
                  key: Key(scan['id']?.toString() ?? index.toString()),
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.delete_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    HapticFeedback.mediumImpact();
                    return await showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: DeleteConfirmationDialogContent(
                          onConfirm: () => onDeleteScan(scan['id']?.toString() ?? ''),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                          Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
                        ],
                      ),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: scan['imageUrl'] != null
                              ? Image.file(
                            File(scan['imageUrl']),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.local_florist_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                              : Icon(
                            Icons.local_florist_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        scan['diagnosis'] ?? 'Unknown Disease',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        scan['timestamp'] ?? 'Unknown Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () => onShowOptions(scan),
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(context, '/results', arguments: scan);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}