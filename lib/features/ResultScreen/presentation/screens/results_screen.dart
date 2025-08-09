import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../Profile/presentation/Components/floating_orb.dart';
import '../../../home/presentation/screens/components/scan_service.dart';
import '../../../home/presentation/screens/components/share_results_dialog_content.dart';
import '../components/app_bar_content.dart';
import '../components/analysis_details_card.dart';
import '../components/diagnosis_card.dart';
import '../components/reccomendations_card.dart';
import '../components/next_steps_card.dart';
import '../components/floating_action_buttons.dart';
import '../components/scanned_image_Section.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> scanData;

  const ResultsScreen({super.key, required this.scanData});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with TickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diagnosisResult = _getDiagnosisResult();
    final hasImage = widget.scanData['imagePath'] != null || widget.scanData['imageUrl'] != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppBarContent(title: 'Analysis Results'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [
              const Color(0xFF0F0F23),
              const Color(0xFF16213E),
              const Color(0xFF1A1A2E),
              const Color(0xFF0F0F23),
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
              8,
                  (index) => FloatingOrb(
                index: index,
                maxWidth: MediaQuery.of(context).size.width,
                fadeController: _fadeController,
                scaleAnimation: _scaleAnimation,
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DiagnosisCard(diagnosisResult: diagnosisResult),
                    const SizedBox(height: 16),
                    AnalysisDetailsCard(scanData: widget.scanData),
                    const SizedBox(height: 16),
                    RecommendationsCard(recommendations: diagnosisResult.recommendations),
                    const SizedBox(height: 16),
                    // In your ResultsScreen build method, change this:
                    if (hasImage) ...[
                      ScannedImageSection(
                        imagePath: widget.scanData['imagePath'] as String, // Only pass imagePath
                      ),
                      const SizedBox(height: 16),
                    ],
                    const NextStepsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButtons(
        onSave: () => _saveReport(context),
        onShare: () => _shareResults(context),
      ),
    );
  }

  DiagnosisResult _getDiagnosisResult() {
    try {
      return DiagnosisResult(
        disease: widget.scanData['diagnosis']?.toString() ?? 'Unknown Disease',
        severity: widget.scanData['severity']?.toString() ?? 'Unknown',
        recommendations: (widget.scanData['treatment']?.toString().split('. ') ?? ['Consult an expert'])
            .where((r) => r.isNotEmpty)
            .toList(),
      );
    } catch (e) {
      debugPrint('Error processing scanData: $e');
      return DiagnosisResult(
        disease: 'Unknown Disease',
        severity: 'Unknown',
        recommendations: ['Consult an expert for further analysis'],
      );
    }
  }

  Future<void> _saveReport(BuildContext context) async {
    HapticFeedback.lightImpact();
    try {
      await ScanService().saveScan({
        'id': widget.scanData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'imageUrl': widget.scanData['imageUrl'],
        'imagePath': widget.scanData['imagePath'],
        'diagnosis': widget.scanData['diagnosis'] ?? 'Unknown Disease',
        'confidence': widget.scanData['confidence']?.toString() ?? '85',
        'treatment': widget.scanData['treatment'] ?? 'Consult an expert',
        'timestamp': widget.scanData['timestamp'] ?? DateTime.now().toIso8601String(),
        'severity': widget.scanData['severity'] ?? 'Unknown',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report saved successfully'),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
              (route) => false,
          arguments: {'newScan': widget.scanData, 'refreshScans': true},
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save report'),
            backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
          ),
        );
      }
      debugPrint('Error saving report: $e');
    }
  }

  Future<void> _shareResults(BuildContext context) async {
    HapticFeedback.lightImpact();
    final shareText = '''
Plant Health Scan Results

Disease: ${widget.scanData['diagnosis'] ?? 'Unknown Disease'}
Date: ${widget.scanData['timestamp'] != null ? _formatDate(DateTime.parse(widget.scanData['timestamp'])) : _formatDate(DateTime.now())}
Confidence: ${widget.scanData['confidence']?.toString() ?? '85'}%

Treatment: ${widget.scanData['treatment'] ?? 'Consult an expert'}

Generated by Plant Health Scanner
''';

    showDialog(
      context: context,
      builder: (context) => ShareResultsDialogContent(shareText: shareText),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class DiagnosisResult {
  final String disease;
  final String severity;
  final List<String> recommendations;

  DiagnosisResult({
    required this.disease,
    required this.severity,
    required this.recommendations,
  });
}