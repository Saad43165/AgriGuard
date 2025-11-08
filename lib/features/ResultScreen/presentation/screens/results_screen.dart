import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io'; // Make sure this import is added
import '../../../../core/constants/app_routes.dart';
import '../../../../services/pdf_generator_service.dart';
import '../../../Profile/presentation/Components/floating_orb.dart';
import '../../../home/presentation/screens/components/scan_service.dart';
import '../../../home/presentation/screens/components/share_results_dialog_content.dart';
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

class _ResultsScreenState extends State<ResultsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Debug: Print the received scan data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('=== RESULTS SCREEN SCAN DATA ===');
      debugPrint(widget.scanData.toString());
      debugPrint('Image path: ${widget.scanData['imagePath']}');
      debugPrint('Image URL: ${widget.scanData['imageUrl']}');
      debugPrint('==============================');
    });
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

    // FIX: Check both imageUrl and imagePath fields
    final String? imagePath = widget.scanData['imagePath'] as String?;
    final String? imageUrl = widget.scanData['imageUrl'] as String?;

    // Debug print to see what we have
    debugPrint('Building ResultsScreen:');
    debugPrint('imagePath: $imagePath');
    debugPrint('imageUrl: $imageUrl');

    // FIX: Check if the file exists - prioritize imageUrl since that's what your data shows
    String? actualImagePath = imageUrl ?? imagePath;
    bool hasLocalImage = false;

    if (actualImagePath != null && actualImagePath.isNotEmpty) {
      try {
        final file = File(actualImagePath);
        hasLocalImage = file.existsSync();
        debugPrint('Local image exists: $hasLocalImage at path: $actualImagePath');
      } catch (e) {
        debugPrint('Error checking file existence: $e');
        hasLocalImage = false;
      }
    }

    final bool hasNetworkImage = imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http');
    final bool hasImage = hasLocalImage || hasNetworkImage;

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

                    // FIX: Image display section - use the actual image path
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
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
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
            .toList(), plantName: '', confidence: '',
      );
    } catch (e) {
      debugPrint('Error processing scanData: $e');
      return DiagnosisResult(
        disease: 'Unknown Disease',
        severity: 'Unknown',
        recommendations: ['Consult an expert for further analysis'], plantName: '', confidence: '',
      );
    }
  }

  Future<void> _saveReport(BuildContext context) async {
    HapticFeedback.lightImpact();

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text('Saving report...'),
            ],
          ),
        ),
      );

      // Save to scan history
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

      // Generate and save PDF report
      try {
        final pdfFile = await PdfShareService.generateScanPdf(widget.scanData);
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadsDir = Directory('${directory.path}/Download');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }

          final fileName = 'AgriGuard_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final newPath = '${downloadsDir.path}/$fileName';
          await pdfFile.copy(newPath);

          debugPrint('PDF saved to: $newPath');
        }
      } catch (pdfError) {
        debugPrint('PDF save failed: $pdfError');
        // Continue even if PDF save fails
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Report saved successfully with PDF!')),
              ],
            ),
            behavior: SnackBarBehavior.fixed,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.1,
            ),
            backgroundColor: Colors.green[700],
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
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save report: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
          ),
        );
      }
      debugPrint('Error saving report: $e');
    }
  }

  Future<void> _shareResults(BuildContext context) async {
    HapticFeedback.lightImpact();

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text('Preparing share...'),
            ],
          ),
        ),
      );

      // Generate PDF for sharing
      final pdfFile = await PdfShareService.generateScanPdf(widget.scanData);

      // Create share text
      final shareText = '''
🌿 AgriGuard Plant Health Scan Results

Diagnosis: ${widget.scanData['diagnosis'] ?? 'Unknown Disease'}
Confidence: ${widget.scanData['confidence']?.toString() ?? '85'}%
Severity: ${widget.scanData['severity'] ?? 'Unknown'}
Date: ${widget.scanData['timestamp'] != null ? _formatDate(DateTime.parse(widget.scanData['timestamp'])) : _formatDate(DateTime.now())}

Treatment Recommendations:
${widget.scanData['treatment'] ?? 'Consult an expert for detailed treatment plan'}

Generated by AgriGuard App
'''.trim();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Share using share_plus
      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(pdfFile.path, mimeType: 'application/pdf')],
          text: shareText,
          subject: 'AgriGuard Plant Health Report',
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Fallback: Share as text only
      final shareText = '''
Plant Health Scan Results

Disease: ${widget.scanData['diagnosis'] ?? 'Unknown Disease'}
Date: ${widget.scanData['timestamp'] != null ? _formatDate(DateTime.parse(widget.scanData['timestamp'])) : _formatDate(DateTime.now())}
Confidence: ${widget.scanData['confidence']?.toString() ?? '85'}%

Treatment: ${widget.scanData['treatment'] ?? 'Consult an expert'}

Generated by Plant Health Scanner
''';

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => ShareResultsDialogContent(shareText: shareText),
        );
      }

      debugPrint('Error sharing results: $e');
    }
  }
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

