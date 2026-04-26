import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:agriguard_fyp/features/advance_result_screen/widgets/AdvancedResultHeaderActions.dart';
import 'package:agriguard_fyp/features/advance_result_screen/widgets/AdvancedResultSections.dart';
import 'package:agriguard_fyp/features/advance_result_screen/widgets/result_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/repositories/scan_repository.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/app_themes.dart';
import '../auth/login/services/guest_service.dart';

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
    // your services sometimes store it in different keys
    final s1 = updatedAnalysisResult['source']?.toString();
    final s2 = updatedAnalysisResult['analysisSource']?.toString();
    final s3 = (updatedAnalysisResult['data'] is Map)
        ? (updatedAnalysisResult['data']['source']?.toString())
        : null;
    return (s1 ?? s2 ?? s3 ?? '').toLowerCase();
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
      final isRoboflow = source.contains('roboflow');

      final savedScan = isGroq
          ? await _scanRepository.saveGroqScan(
        analysisResult: updatedAnalysisResult,
        imagePath: imagePath,
      )
          : isRoboflow
          ? await _scanRepository.saveRoboflowScan(
        analysisResult: updatedAnalysisResult,
        imagePath: imagePath,
      )
          : await _scanRepository.savePlantIdScan(
        analysisResult: updatedAnalysisResult,
        imagePath: imagePath,
      );

      debugPrint('Advanced scan auto-saved → ID: ${savedScan.id}');

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

    final source = widget.analysisResult['source'] as String? ?? 'AI';
    final plantRaw = data['plantName'] as String? ?? data['plant'] as String? ?? '-';
    final diseaseRaw = data['diseaseName'] as String? ?? data['disease'] as String? ?? '-';
    final severityRaw = data['severity'] as String? ?? '-';
    final confidence = data['confidence'];
    final confText = confidence != null ? '$confidence%' : '-';

    final plant = t.translatePlant(plantRaw);
    final disease = diseaseRaw.toLowerCase() == 'healthy'
        ? (t.isUrdu ? 'صحت مند' : 'Healthy')
        : t.translateDisease(diseaseRaw);
    final severity = t.translateSeverity(severityRaw);

    final text = t.isUrdu
        ? '''🌿 AgriGuard ایڈوانسڈ نتائج

🔬 ذریعہ: $source
🌱 پودا: $plant
🦠 بیماری: $disease
⚠️ شدت: $severity
📊 اعتماد: $confText'''
        : '''🌿 AgriGuard Advanced Results

🔬 Source: $source
🌱 Plant: $plant
🦠 Disease: $disease
⚠️ Severity: $severity
📊 Confidence: $confText''';

    await Share.share(text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);

    final data = widget.analysisResult['data'] as Map<String, dynamic>? ?? {};
    final hasDiseaseInfo = widget.analysisResult['hasDiseaseInfo'] as bool? ?? false;
    final source = widget.analysisResult['source'] as String? ?? 'AI';

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 22),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          t.get('results.advanced_title'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        actions: [
          AdvancedResultHeaderActions(
            isUrdu: t.isUrdu,
            onShare: () => _handleShare(t, data),
            onToggleLanguage: () {
              HapticFeedback.lightImpact();
              t.toggleLanguage();
            },
            shareTooltip: t.get('share'),
            languageTooltip: t.isUrdu
                ? t.get('buttons.switch_to_english')
                : t.get('buttons.switch_to_urdu'),
          ),
        ],
      ),
      floatingActionButton: ResultActionButton(
        analysisResult: widget.analysisResult,
        originalScanData: widget.originalScanData,
        plantImageBytes: _imageBytes,
      ),
      body: AdvancedResultSections(
        analysisResult: widget.analysisResult,
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