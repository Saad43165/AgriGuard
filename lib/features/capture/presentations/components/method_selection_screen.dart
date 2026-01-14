import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';
import 'method_card.dart';
import 'step_header.dart';
import 'comparison_table.dart';

class MethodSelectionScreen extends StatelessWidget {
  final bool isTFLiteReady;
  final String? loadingText;
  final VoidCallback onSelectTFLite;
  final VoidCallback onSelectAPI;
  final ScrollController scrollController;

  const MethodSelectionScreen({
    super.key,
    required this.isTFLiteReady,
    this.loadingText,
    required this.onSelectTFLite,
    required this.onSelectAPI,
    required this.scrollController, required Map<String, bool> modelDetails,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Header
          StepHeader(
            title: 'Choose Analysis Method',
            subtitle: 'Select how you want to analyze your plant photo',
            stepNumber: 1,
          ),

          const SizedBox(height: 32),

          // TFLite Option
          MethodCard(
            method: 'tflite',
            icon: Icons.phone_android_rounded,
            title: 'On-Device Analysis',
            subtitle: 'Fast & Private',
            description: 'Uses AI directly on your device - no internet needed',
            features: [
              'Instant results',
              '100% private & offline',
              '12 common plant species',
              'Free unlimited scans',
            ],
            gradient: [
              const Color(0xFF00B4DB),
              const Color(0xFF0083B0),
            ],
            isReady: isTFLiteReady,
            loadingText: loadingText,
            onSelect: onSelectTFLite,
          ),

          const SizedBox(height: 24),

          // API Option
          MethodCard(
            method: 'api',
            icon: Icons.cloud_rounded,
            title: 'Advanced AI Search',
            subtitle: 'Comprehensive & Powerful',
            description: 'Cloud-powered analysis with extensive database',
            features: [
              '50,000+ plant species',
              'Detailed health analysis',
              'Treatment recommendations',
              'Advanced disease detection',
            ],
            gradient: [
              const Color(0xFF6A11CB),
              const Color(0xFF2575FC),
            ],
            isReady: true,
            onSelect: onSelectAPI,
          ),
          const SizedBox(height: 32),

          // Comparison Table
          ComparisonTable(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}