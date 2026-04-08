// lib/features/ResultScreen/presentation/advanced_results_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_measurements.dart';
import '../../../../core/services/translation_service.dart';
import '../../../core/widgets/floating_orb.dart';
import 'components/additional_info_card.dart';
import 'components/diagnosis_card.dart';
import 'components/image_preview_results.dart';
import 'components/result_action_button.dart' show ResultActionButton;
import 'components/section_card.dart';
import 'components/source_badge.dart';
import '../../../../core/repositories/scan_repository.dart';
import '../auth/Login_Screen/services/guest_service.dart';

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

  late final ScanRepository _scanRepository;
  final GuestService _guestService = GuestService();
  bool _isGuestMode = false;

  bool _isProcessing = false;
  bool _isAlreadySaved = false;
  Uint8List? _imageBytes; // Add this to store image bytes

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scanRepository = ScanRepository();
    _loadImageBytes(); // Load image bytes on init
    _initializeGuestMode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAutoSaveScan();
    });
  }

  Future<void> _initializeGuestMode() async {
    await _guestService.initialize();
    if (mounted) setState(() => _isGuestMode = _guestService.isGuestMode);
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

  // Add this method to load image bytes
  Future<void> _loadImageBytes() async {
    try {
      final imagePath = widget.originalScanData['imagePath'] as String?;
      final imageBase64 = widget.originalScanData['imageBase64'] as String?;

      if (imageBase64 != null) {
        // Decode base64 to bytes
        _imageBytes = base64Decode(imageBase64);
      } else if (imagePath != null) {
        // Load from file
        final file = File(imagePath);
        if (await file.exists()) {
          _imageBytes = await file.readAsBytes();
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading image bytes: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _generateScanId() {
    final dataHash = jsonEncode(widget.analysisResult).hashCode.abs();
    final imagePathHash = widget.originalScanData['imagePath']?.hashCode ?? 0;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'advanced_${dataHash}_${imagePathHash}_$timestamp';
  }

  Future<void> _checkAndAutoSaveScan() async {
    final isFromHistory = widget.originalScanData['isFromHistory'] == true ||
        widget.originalScanData['skipSave'] == true ||
        widget.originalScanData['databaseId'] != null;

    if (isFromHistory) {
      debugPrint('📂 Opening advanced scan from history - skipping auto-save');
      setState(() => _isAlreadySaved = true);
      return;
    }

    if (_isAlreadySaved || _isProcessing) return;
    if (_isGuestMode) return;

    setState(() => _isProcessing = true);

    try {
      final originalId = widget.originalScanData['id'] as String?;
      final scanId = originalId ?? _generateScanId();

      final existing = await _scanRepository.getScanById(scanId);
      if (existing != null) {
        debugPrint('✅ Advanced scan already exists → skipping save');
        setState(() {
          _isAlreadySaved = true;
          _isProcessing = false;
        });
        return;
      }

      String? imageBase64 = widget.originalScanData['imageBase64'] as String?;
      final imagePath = widget.originalScanData['imagePath'] as String?;

      if (imageBase64 == null && imagePath != null) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            imageBase64 = base64Encode(bytes);
          }
        } catch (e) {
          debugPrint('⚠️ Failed to convert image to base64: $e');
        }
      }

      final updatedAnalysisResult = {
        ...widget.analysisResult,
        'scanId': scanId,
      };

      final source = updatedAnalysisResult['source']?.toString().toLowerCase() ?? 'groq';
      final isGroq = source.contains('groq');
      final isHuggingFace = source.contains('hugging') || source.contains('hf');

      final savedScan = isGroq
          ? await _scanRepository.saveGroqScan(
              analysisResult: updatedAnalysisResult,
              imagePath: imagePath,
            )
          : isHuggingFace
              ? await _scanRepository.saveHuggingFaceScan(
                  analysisResult: updatedAnalysisResult,
                  imagePath: imagePath,
                )
              : await _scanRepository.savePlantIdScan(
                  analysisResult: updatedAnalysisResult,
                  imagePath: imagePath,
                );

      debugPrint('✅ Advanced scan auto-saved → ID: ${savedScan.id}');

      if (mounted) {
        setState(() {
          _isAlreadySaved = true;
          _isProcessing = false;
        });
      }
    } catch (e, stack) {
      debugPrint('❌ Auto-save failed: $e');
      debugPrint('Stack: $stack');

      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
    final t = Provider.of<TranslationService>(context);
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
          t.get('results.advanced_title'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
          ),
        ),
      ),
      floatingActionButton: ResultActionButton(
        analysisResult: widget.analysisResult,
        originalScanData: widget.originalScanData,
        plantImageBytes: _imageBytes, // Pass the loaded image bytes
        // The button handles its own share and PDF generation internally now
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
                      SourceBadge(
                        result: widget.analysisResult,
                        theme: theme,
                      ),
                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),
                      DiagnosisCard(
                        theme: theme,
                        data: data,
                        getSeverityColor: _getSeverityColor,
                      ),
                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),
                      ImagePreviewResults(
                        originalScanData: widget.originalScanData,
                        theme: theme,
                      ),
                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),
                      SectionCard(
                        theme: theme,
                        title: 'Symptoms Detected',
                        icon: Icons.visibility_outlined,
                        items: (data['symptoms'] as List<dynamic>?)
                            ?.cast<String>() ??
                            [],
                        color: Colors.blue,
                      ),
                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),
                      SectionCard(
                        theme: theme,
                        title: 'Treatment Recommendations',
                        icon: Icons.medical_services_outlined,
                        items: (data['remediation'] as List<dynamic>?)
                            ?.cast<String>() ??
                            [],
                        color: Colors.green,
                      ),
                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),
                      SectionCard(
                        theme: theme,
                        title: 'Preventive Measures',
                        icon: Icons.shield_outlined,
                        items: (data['precautions'] as List<dynamic>?)
                            ?.cast<String>() ??
                            [],
                        color: Colors.orange,
                      ),
                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),
                      if (data['additionalInfo'] != null)
                        AdditionalInfoCard(
                          theme: theme,
                          info: data['additionalInfo'] as String,
                          hasDiseaseInfo: hasDiseaseInfo,
                        ),
                      if (_isAlreadySaved)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.green.withOpacity(0.7),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Saved to history',
                                  style: TextStyle(
                                    color: Colors.green.withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context) * 2.5,
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