import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../Profile/presentation/Components/glass_card.dart';
import 'guide_step.dart';

class FirstTimeUserGuide extends StatelessWidget {
  const FirstTimeUserGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ).createShader(bounds),
              child: Text(
                'How to Get Started',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 24),
            GuideStep(
              icon: Icons.camera_alt_rounded,
              title: 'Step 1. Scan Your Plant',
              description: 'Capture a clear photo of the leaf showing symptoms',
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            GuideStep(
              icon: Icons.analytics_rounded,
              title: 'Step 2. Get Diagnosis',
              description: 'Our AI analyzes the symptoms and identifies the disease',
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 20),
            GuideStep(
              icon: Icons.medical_services_rounded,
              title: 'Step 3. View Recommendations',
              description: 'Receive tailored treatment advice for your plant',
              color: Theme.of(context).colorScheme.tertiary ?? Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}