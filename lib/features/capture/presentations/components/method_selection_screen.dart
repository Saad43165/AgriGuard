import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/services/translation_service.dart';
import 'method_card.dart';
import 'step_header.dart';
import 'comparison_table.dart';

class MethodSelectionScreen extends StatefulWidget {
  final bool isTFLiteReady;
  final String? loadingText;
  final VoidCallback onSelectTFLite;
  final VoidCallback onSelectAPI;
  final ScrollController scrollController;
  final Map<String, bool> modelDetails;

  const MethodSelectionScreen({
    super.key,
    required this.isTFLiteReady,
    this.loadingText,
    required this.onSelectTFLite,
    required this.onSelectAPI,
    required this.scrollController,
    required this.modelDetails,
  });

  @override
  State<MethodSelectionScreen> createState() => _MethodSelectionScreenState();
}

class _MethodSelectionScreenState extends State<MethodSelectionScreen> {
  String? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    final translation = TranslationService();

    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return SingleChildScrollView(
          controller: widget.scrollController,
          padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Header
              StepHeader(
                title: translation.get('method_title'),
                subtitle: translation.get('method_subtitle'),
                stepNumber: 1,
              ),

              const SizedBox(height: 24),

              // TFLite Option
              MethodCard(
                method: 'tflite',
                icon: Icons.phone_android_rounded,
                title: translation.get('on_device'),
                subtitle: translation.get('on_device_desc'),
                description:
                translation.get('on_device_features').split('\n').first,
                features: translation
                    .get('on_device_features')
                    .split('\n')
                    .map((e) => e.replaceAll('• ', '').trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                gradient: const [
                  Color(0xFF00B4DB),
                  Color(0xFF0083B0),
                ],
                isReady: widget.isTFLiteReady,
                loadingText: widget.loadingText ?? translation.get('model_loading'),
                onSelect: () {
                  setState(() => _selectedMethod = 'tflite');
                  widget.onSelectTFLite();
                },
              ),

              const SizedBox(height: 16),

              // API Option
              MethodCard(
                method: 'api',
                icon: Icons.cloud_rounded,
                title: translation.get('advanced_ai'),
                subtitle: translation.get('advanced_ai_desc'),
                description:
                translation.get('advanced_ai_features').split('\n').first,
                features: translation
                    .get('advanced_ai_features')
                    .split('\n')
                    .map((e) => e.replaceAll('• ', '').trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                gradient: const [
                  Color(0xFF6A11CB),
                  Color(0xFF2575FC),
                ],
                isReady: true,
                onSelect: () {
                  setState(() => _selectedMethod = 'api');
                  widget.onSelectAPI();
                },
              ),

              const SizedBox(height: 24),

              // Comparison Table
              const ComparisonTable(),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}