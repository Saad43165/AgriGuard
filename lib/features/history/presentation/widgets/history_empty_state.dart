import 'package:agriguard_fyp/features/capture/presentations/capture_screen.dart';
import 'package:flutter/material.dart';

class HistoryEmptyStateWidget extends StatelessWidget {
  final bool isAdvanced;

  const HistoryEmptyStateWidget({
    super.key,
    required this.isAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.secondary.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAdvanced
                    ? Icons.cloud_off_rounded
                    : Icons.phonelink_off_rounded,
                size: 40,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),

            SizedBox(height: 12),

            Text(
              isAdvanced
                  ? 'No Advanced AI Scans'
                  : 'No On-Device Scans',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 12),

            Text(
              isAdvanced
                  ? 'Advanced AI scans use cloud services for detailed plant analysis with disease detection'
                  : 'On-device scans use local AI models for quick plant identification',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 32),

            FilledButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CaptureScreen()), // Replace ScanScreen with your actual class name
                );
              },              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(Icons.add_rounded),
              label: Text(
                'Start Scanning',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}