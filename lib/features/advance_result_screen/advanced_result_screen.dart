// lib/features/ResultScreen/presentation/advanced_results_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../core/widgets/floating_orb.dart';
import 'components/additional_info_card.dart';
import 'components/diagnosis_card.dart';
import 'components/image_preview_results.dart';

import 'components/section_card.dart';
import 'components/source_badge.dart';

class AdvancedResultsScreen extends StatefulWidget {
  final Map<String, dynamic> analysisResult;
  final Map<String, dynamic> originalScanData;

  const AdvancedResultsScreen({
    super.key,
    required this.analysisResult,
    required this.originalScanData,
  });

  @override
  State<AdvancedResultsScreen> createState() => _AdvancedResultsScreenState();
}

class _AdvancedResultsScreenState extends State<AdvancedResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade700;
      case 'healthy':
      case 'none':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.analysisResult['data'] as Map<String, dynamic>;
    final hasDiseaseInfo = widget.analysisResult['hasDiseaseInfo'] as bool? ?? false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Advanced Results',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? const [
              Color(0xFF0F0F23),
              Color(0xFF16213E),
              Color(0xFF1A1A2E),
              Color(0xFF0F0F23),
            ]
                : [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.9),
              theme.colorScheme.surface.withOpacity(0.8),
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ...List.generate(
              6,
                  (i) => FloatingOrb(
                index: i,
                maxWidth: MediaQuery.of(context).size.width,
                fadeController: _fadeController,
                scaleAnimation: _scaleAnimation,
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeController,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                    AppMeasurements.getResponsivePadding(context) * 0.4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source badge
                      SourceBadge(
                        result: widget.analysisResult,
                        theme: theme,
                      ),

                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),

                      // Main diagnosis card
                      DiagnosisCard(
                        theme: theme,
                        data: data,
                        getSeverityColor: _getSeverityColor,
                      ),

                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),

                      // Image preview
                      ImagePreviewResults(
                        originalScanData: widget.originalScanData,
                        theme: theme,
                      ),

                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),

                      // Symptoms section
                      SectionCard(
                        theme: theme,
                        title: 'Symptoms Detected',
                        icon: Icons.visibility_outlined,
                        items: (data['symptoms'] as List<dynamic>?)?.cast<String>() ?? [],
                        color: Colors.blue,
                      ),

                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),

                      // Remediation section
                      SectionCard(
                        theme: theme,
                        title: 'Treatment Recommendations',
                        icon: Icons.medical_services_outlined,
                        items: (data['remediation'] as List<dynamic>?)?.cast<String>() ?? [],
                        color: Colors.green,
                      ),

                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),

                      // Precautions section
                      SectionCard(
                        theme: theme,
                        title: 'Preventive Measures',
                        icon: Icons.shield_outlined,
                        items: (data['precautions'] as List<dynamic>?)?.cast<String>() ?? [],
                        color: Colors.orange,
                      ),

                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),

                      // Additional info
                      if (data['additionalInfo'] != null)
                        AdditionalInfoCard(
                          theme: theme,
                          info: data['additionalInfo'] as String,
                          hasDiseaseInfo: hasDiseaseInfo,
                        ),

                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context) * 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}