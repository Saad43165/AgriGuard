import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADD THIS IMPORT

import '../../../../core/constants/app_routes.dart';
import '../../../Profile/presentation/Components/floating_orb.dart';
import '../../../home/screens/components/scan_service.dart';
import '../../../home/screens/components/share_results_dialog_content.dart';
import '../components/app_bar_content.dart';
import '../components/analysis_details_card.dart';
import '../components/diagnosis_card.dart';
import '../components/diagnosis_result.dart';
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

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isSaving = false;

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

  // ADD THIS METHOD: Handle both String and Timestamp
  String _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      if (timestamp is Timestamp) {
        // Handle Firestore Timestamp
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (timestamp is String) {
        // Handle string timestamp
        return timestamp; // Return as-is since it's already formatted
      } else {
        return 'Unknown date';
      }
    } catch (e) {
      debugPrint('Timestamp parse error: $e');
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diagnosisResult = _getDiagnosisResult();

    final String? imagePath = widget.scanData['imagePath'] as String?;
    final String? imageUrl = widget.scanData['imageUrl'] as String?;

    String? actualImagePath = imageUrl ?? imagePath;
    bool hasLocalImage = false;

    if (actualImagePath != null && actualImagePath.isNotEmpty) {
      try {
        final file = File(actualImagePath);
        hasLocalImage = file.existsSync();
      } catch (e) {
        debugPrint('Error checking file existence: $e');
        hasLocalImage = false;
      }
    }

    final bool hasNetworkImage = imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http');
    final bool hasImage = hasLocalImage || hasNetworkImage;

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarContent(
          title: 'Analysis Results',
          showBackButton: !_isSaving,
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

                      if (hasImage)
                        Column(
                          children: [
                            if (hasLocalImage && actualImagePath != null)
                              ScannedImageSection(imagePath: actualImagePath)
                            else if (hasNetworkImage)
                              _buildNetworkImage(imageUrl!, theme)
                            else
                              _buildNoImagePlaceholder(theme),
                            const SizedBox(height: 16),
                          ],
                        )
                      else
                        _buildNoImagePlaceholder(theme),

                      const NextStepsCard(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              if (_isSaving)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Saving report...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: _isSaving
            ? null
            : FloatingActionButtons(
          heroTagPrefix: 'results_screen',
          onSave: () => _saveReport(context),
          onShare: () => _shareResults(context),
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 250,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildNoImagePlaceholder(theme);
          },
        ),
      ),
    );
  }

  Widget _buildNoImagePlaceholder(ThemeData theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No image available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
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
        plantName: widget.scanData['plantName']?.toString() ?? '',
        confidence: widget.scanData['confidence']?.toString() ?? '0',
      );
    } catch (e) {
      debugPrint('Error processing scanData: $e');
      return DiagnosisResult(
        disease: 'Unknown Disease',
        severity: 'Unknown',
        recommendations: ['Consult an expert for further analysis'],
        plantName: '',
        confidence: '0',
      );
    }
  }

  Future<void> _saveReport(BuildContext context) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      // Handle timestamp conversion for saving
      dynamic timestampToSave = widget.scanData['timestamp'];
      if (timestampToSave is Timestamp) {
        timestampToSave = timestampToSave.toDate().toIso8601String();
      }

      await ScanService().saveScan({
        'id': widget.scanData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'imageUrl': widget.scanData['imageUrl'],
        'imagePath': widget.scanData['imagePath'],
        'diagnosis': widget.scanData['diagnosis'] ?? 'Unknown Disease',
        'confidence': widget.scanData['confidence']?.toString() ?? '85',
        'treatment': widget.scanData['treatment'] ?? 'Consult an expert',
        'timestamp': timestampToSave ?? DateTime.now().toIso8601String(),
        'severity': widget.scanData['severity'] ?? 'Unknown',
      });

      if (!mounted) return;

      // Go back to previous screen (History, Home, etc.)
      Navigator.pop(context);

      // Then go to Home with refresh
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
            (route) => false,
        arguments: {'newScan': widget.scanData, 'refreshScans': true},
      );
    } catch (e) {
      debugPrint('Error saving report: $e');
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save report. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _saveReport(context),
          ),
        ),
      );
    }
  }

  Future<void> _shareResults(BuildContext context) async {
    HapticFeedback.lightImpact();

    String dateStr = 'Unknown date';
    final timestamp = widget.scanData['timestamp'];

    // HANDLE BOTH STRING AND TIMESTAMP
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } else if (timestamp is String && timestamp.contains('/')) {
      try {
        final parts = timestamp.split(' ');
        final datePart = parts[0];
        final dateComponents = datePart.split('/');
        final day = int.parse(dateComponents[0]);
        final month = int.parse(dateComponents[1]);
        final year = int.parse(dateComponents[2]);
        dateStr = '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
      } catch (e) {
        debugPrint('Failed to parse timestamp: $e');
        dateStr = _formatDate(DateTime.now());
      }
    } else {
      dateStr = _formatDate(DateTime.now());
    }

    final shareText = '''
Plant Health Scan Results

Disease: ${widget.scanData['diagnosis'] ?? 'Unknown Disease'}
Date: $dateStr
Confidence: ${widget.scanData['confidence']?.toString() ?? '85'}%

Treatment: ${widget.scanData['treatment'] ?? 'Consult an expert'}

Generated by Plant Health Scanner
''';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => ShareResultsDialogContent(shareText: shareText),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}