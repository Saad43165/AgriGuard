import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';
import 'feature_highlights.dart';
import 'how_it_works.dart';
import 'guest_stats.dart';

class WelcomeScreen extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final bool isGuestMode;
  final int remainingScans;
  final VoidCallback onStartScan;

  const WelcomeScreen({
    super.key,
    required this.scaleAnimation,
    required this.isGuestMode,
    required this.remainingScans,
    required this.onStartScan, required Map<String, bool> modelStatuses,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Header with clear purpose
          _buildHeader(context),

          const SizedBox(height: 32),

          // What you can achieve
          Text(
            'What You Can Achieve',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Our AI-powered scanner helps you identify plants and detect diseases instantly. '
                'Get accurate diagnosis and treatment recommendations in seconds.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Feature Highlights
          const FeatureHighlights(),

          const SizedBox(height: 40),

          // How It Works
          const HowItWorks(),

          const SizedBox(height: 32),

          // Quick Stats if guest
          if (isGuestMode)
            GuestStats(remainingScans: remainingScans),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Simply take a photo of any plant leaf to start the analysis',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}