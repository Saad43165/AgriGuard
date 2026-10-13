import 'dart:convert';
import 'dart:io';
import 'package:agriguard_fyp/features/advance_result_screen/widgets/AdvancedResultHeaderActions.dart';
import 'package:agriguard_fyp/features/advance_result_screen/widgets/AdvancedResultSections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/scan_repository.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/app_themes.dart';
import '../../features/home/screens/PdfDialogs/services/pdf_action_services.dart';
import '../../features/home/screens/PdfDialogs/SuccessPdfDialog/pdf_success_dialog.dart';
import '../auth/login/services/guest_service.dart';
import '../advance_search_screen/service/groq_service.dart';

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

class _AdvancedResultsScreenState extends State<AdvancedResultsScreen> {
  late final ScanRepository _scanRepository;
  final GuestService _guestService = GuestService();
  final GroqService _groqService = GroqService();

  Map<String, dynamic>? _urduOverrideData;
  bool _isTranslating = false;

  bool _isGuestMode = false;
  bool _isProcessing = false;
  bool _isAlreadySaved = false;
  Uint8List? _imageBytes;

  bool _symptomsExpanded = true;
  bool _treatmentExpanded = true;
  bool _preventiveExpanded = true;

  @override
  void initState() {
    super.initState();
    _scanRepository = ScanRepository();
    _loadImageBytes();
    _initializeGuestMode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndAutoSaveScan());
  }

  Future<void> _initializeGuestMode() async {
    await _guestService.initialize();
    if (mounted) setState(() => _isGuestMode = _guestService.isGuestMode);
  }

  Future<void> _loadImageBytes() async {
    try {
      final imagePath = widget.originalScanData['imagePath'] as String?;
      final imageBase64 = widget.originalScanData['imageBase64'] as String?;

      if (imageBase64 != null) {
        _imageBytes = base64Decode(imageBase64);
      } else if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) _imageBytes = await file.readAsBytes();
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading image bytes: $e');
    }
  }

  String _generateScanId() {
    final dataHash = jsonEncode(widget.analysisResult).hashCode.abs();
    final imagePathHash = widget.originalScanData['imagePath']?.hashCode ?? 0;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'advanced_${dataHash}_${imagePathHash}_$timestamp';
  }

  bool _isFromHistory() {
    return widget.originalScanData['isFromHistory'] == true ||
        widget.originalScanData['skipSave'] == true ||
        widget.originalScanData['databaseId'] != null;
  }

  String _detectSourceLower(Map<String, dynamic> updatedAnalysisResult) {
    final s1 = updatedAnalysisResult['source']?.toString();
    final s2 = updatedAnalysisResult['analysisSource']?.toString();
    final s3 = (updatedAnalysisResult['data'] is Map)
        ? (updatedAnalysisResult['data']['source']?.toString())
        : null;
    return (s1 ?? s2 ?? s3 ?? '').toLowerCase();
  }

  Future<void> _translateAllDataToUrduIfNeeded(TranslationService t) async {
    if (!t.isUrdu) return;
    if (_isTranslating || _urduOverrideData != null) return;

    if (!_groqService.hasApiKey()) {
      debugPrint('⚠️ GROQ_API_KEY missing, cannot translate dynamic text.');
      return;
    }

    final data = widget.analysisResult['data'];
    if (data is! Map) return;

    setState(() => _isTranslating = true);
    try {
      final res = await _groqService.translateScanDataToUrdu(
        data: Map<String, dynamic>.from(data),
      );

      if (res['success'] == true && res['data'] is Map) {
        if (!mounted) return;
        setState(() {
          _urduOverrideData = Map<String, dynamic>.from(res['data'] as Map);
        });
      } else {
        debugPrint('⚠️ Translation failed: ${res['message'] ?? res}');
      }
    } catch (e, st) {
      debugPrint('❌ Translation exception: $e\n$st');
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _checkAndAutoSaveScan() async {
    if (_isFromHistory()) {
      if (mounted) setState(() => _isAlreadySaved = true);
      return;
    }

    if (_isAlreadySaved || _isProcessing || _isGuestMode) return;

    setState(() => _isProcessing = true);

    try {
      final originalId = widget.originalScanData['id'] as String?;
      final scanId = originalId ?? _generateScanId();

      final existing = await _scanRepository.getScanById(scanId);
      if (existing != null) {
        if (!mounted) return;
        setState(() {
          _isAlreadySaved = true;
          _isProcessing = false;
        });
        return;
      }

      final updatedAnalysisResult = {
        ...widget.analysisResult,
        'scanId': scanId,
      };

      final source = _detectSourceLower(updatedAnalysisResult);
      final imagePath = widget.originalScanData['imagePath'] as String?;

      final isGroq = source.contains('groq');
      final isPlantHealth = source.contains('planthealth');
      final isPlantId = source.contains('plantid') || source.contains('plant.id') || !isGroq && !isPlantHealth;

      final savedScan = isGroq
          ? await _scanRepository.saveGroqScan(
        analysisResult: updatedAnalysisResult,
        imagePath: imagePath,
      )
          : isPlantHealth
          ? await _scanRepository.savePlantHealthScan(
        analysisResult: updatedAnalysisResult,
        imagePath: imagePath,
      )
          : await _scanRepository.savePlantIdScan(
        analysisResult: updatedAnalysisResult,
        imagePath: imagePath,
      );

      debugPrint('Advanced scan auto-saved → ID: ${savedScan.id} (source: $source)');

      if (!mounted) return;
      setState(() {
        _isAlreadySaved = true;
        _isProcessing = false;
      });
    } catch (e, stack) {
      debugPrint('Auto-save failed: $e\n$stack');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleShare(
      TranslationService t,
      Map<String, dynamic> data,
      ) async {
    HapticFeedback.lightImpact();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final scanDataForPdf = {
      ...widget.analysisResult,
      'data': _urduOverrideData ?? data,
    };

    final pdfService = PdfActionsService();
    
    await pdfService.generateAndShowPdf(
      context: context,
      scan: scanDataForPdf,
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onSuccess: (pdfFile) async {
        await _showPdfSuccessDialog(pdfFile);
      },
    );
  }

  Future<void> _showPdfSuccessDialog(File pdfFile) async {
    final dialog = PdfSuccessDialog(pdfFile: pdfFile);
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => dialog,
    );
    
    if (result == null) return;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);

    // Apply override data when Urdu translation is ready
    final effectiveResult = <String, dynamic>{
      ...widget.analysisResult,
      'data': _urduOverrideData ?? (widget.analysisResult['data'] ?? {}),
    };

    final data = effectiveResult['data'] as Map<String, dynamic>? ?? {};
    final hasDiseaseInfo = effectiveResult['hasDiseaseInfo'] as bool? ?? false;
    final source = effectiveResult['source'] as String? ?? 'AI';

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(tooltip: 'Back', 
          icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 22),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          t.get('results.advanced_title'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        ),
        actions: [
          AdvancedResultHeaderActions(
            isUrdu: t.isUrdu,
            onShare: () => _handleShare(t, data),
            onToggleLanguage: () async {
              HapticFeedback.lightImpact();
              t.toggleLanguage();

              if (t.isUrdu) {
                await _translateAllDataToUrduIfNeeded(t);
              } else {
                if (mounted) setState(() => _urduOverrideData = null);
              }
            },
            shareTooltip: t.get('share'),
            languageTooltip: t.isUrdu
                ? t.get('buttons.switch_to_english')
                : t.get('buttons.switch_to_urdu'),
          ),
          if (_isTranslating)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: AdvancedResultSections(
        analysisResult: effectiveResult,
        originalScanData: widget.originalScanData,
        imageBytes: _imageBytes,
        hasDiseaseInfo: hasDiseaseInfo,
        source: source,
        symptomsExpanded: _symptomsExpanded,
        treatmentExpanded: _treatmentExpanded,
        preventiveExpanded: _preventiveExpanded,
        onToggleSymptoms: () => setState(() => _symptomsExpanded = !_symptomsExpanded),
        onToggleTreatment: () => setState(() => _treatmentExpanded = !_treatmentExpanded),
        onTogglePreventive: () => setState(() => _preventiveExpanded = !_preventiveExpanded),
        isAlreadySaved: _isAlreadySaved,
      ),
    );
  }
}