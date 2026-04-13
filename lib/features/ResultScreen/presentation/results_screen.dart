import 'dart:async';
import 'dart:convert';
import 'package:agriguard_fyp/features/ResultScreen/presentation/components/advanced_search_button.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/components/image_section.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/components/loading_indicator.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/components/next_steps_card.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/components/pdf_floating_button.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/components/result_appbar.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/service/pdf_generation_service.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/service/scan_save_service.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/utils/constants.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/utils/data_parsers.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/utils/disease_cause_extractor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../auth/Login_Screen/services/guest_service.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/repositories/scan_repository.dart';
import '../../../../core/services/severity_id_service.dart';
import '../../../../core/widgets/app_themes.dart';
import '../../../core/widgets/floating_orb.dart';
import 'components/diagnosis_card.dart';
import '../../advance_search_screen/advanced_search_screen.dart';
import 'components/analysis_details_Card.dart' show AnalysisDetailsCard;
import 'components/disease_cause_card.dart' show DiseaseCausesCard;
import 'components/floating_advance_search_banner.dart';
import 'components/recommentations_card.dart' show RecommendationsCard;
import 'models/diagnosis_result.dart';
import 'models/leaf_analysis_result.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> scanData;

  const ResultsScreen({
    required this.scanData,
    super.key,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  // State Variables
  bool _isSaving = false;
  bool _isAlreadySaved = false;
  bool _showAdvancedSearchBanner = false;
  bool _jsonLoaded = false;
  bool _isGeneratingPdf = false;
  Timer? _advancedSearchTimer;

  // Analysis Results
  LeafAnalysisResult? _leafAnalysis;
  bool get _isLeafImage =>
      _leafAnalysis?.isLeaf ?? (widget.scanData['isLeaf'] as bool? ?? true);

  // Data Variables
  final Map<String, dynamic> _diseaseCauses = {};
  final Map<String, dynamic> _diseaseMapping = {};
  List<dynamic> _diseaseCausesList = [];

  // Severity and Remediation
  // FIX 4: Default to 'None' not 'Medium' — a scan with no severity data
  // should not show "Medium" which implies disease when plant may be healthy.
  String _severity = 'None';
  List<String> _remediation = [];
  bool _isLoadingSeverityRemediation = false;

  // Services
  late final ScanRepository _scanRepository;
  late final SeverityIdService _severityIdService;
  late final ScanSaveService _scanSaveService;
  final PdfGenerationService _pdfService = PdfGenerationService();
  final GuestService _guestService = GuestService();
  bool _isGuestMode = false;

  @override
  void initState() {
    super.initState();
    _initializeGuestMode();
    _initializeServices();
    _initializeAnimations();
    _loadJsonData();
    _scheduleAdvancedSearchBanner();
    _analyzeImageAndSave();
  }

  Future<void> _initializeGuestMode() async {
    await _guestService.initialize();
    if (mounted) setState(() => _isGuestMode = _guestService.isGuestMode);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _advancedSearchTimer?.cancel();
    super.dispose();
  }

  void _initializeServices() {
    _scanRepository = ScanRepository();
    _severityIdService = SeverityIdService();
    _scanSaveService = ScanSaveService(
      scanRepository: _scanRepository,
    );
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: ResultScreenConstants.animationDuration,
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: ResultScreenConstants.scaleAnimationDuration,
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(
      begin: ResultScreenConstants.scaleBegin,
      end: ResultScreenConstants.scaleEnd,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: ResultScreenConstants.scaleCurve,
      ),
    );
  }

  Future<void> _analyzeImageAndSave() async {
    setState(() => _isLoadingSeverityRemediation = true);

    try {
      // Leaf decision is made upstream (capture/orchestrator). Do NOT rerun
      // another heuristic leaf detector here, or it can contradict the scan.
      final leafFromScan = widget.scanData['leafAnalysis'];
      if (leafFromScan is Map<String, dynamic>) {
        _leafAnalysis = LeafAnalysisResult.fromJson(leafFromScan);
      } else {
        final isLeaf = widget.scanData['isLeaf'] as bool? ?? true;
        final leafConfidence = (widget.scanData['leafConfidence'] as num?)?.toDouble() ?? 50.0;
        _leafAnalysis = LeafAnalysisResult(
          isLeaf: isLeaf,
          confidence: leafConfidence,
          reasons: isLeaf
              ? const ['Upstream analysis marked this as a leaf image']
              : const ['Upstream analysis marked this as a non-leaf image'],
          details: widget.scanData['leafDetectionDetails'] as Map<String, dynamic>?,
        );
      }

      debugPrint('🍃 Leaf status from scanData:');
      debugPrint('   Is Leaf: ${_leafAnalysis!.isLeaf}');
      debugPrint('   Confidence: ${_leafAnalysis!.confidence.toStringAsFixed(1)}%');

      if (_leafAnalysis!.isLeaf) {
        await _getSeverityAndRemediation();
      } else {
        // Non-leaf scans should already contain correct messaging + flags.
        _severity = 'N/A';
        _remediation = DataParsers.parseStringToList(
          widget.scanData['remediation'] ?? widget.scanData['treatment'],
        );
      }

      // FIX 2: Check shouldSaveToHistory flag set by plant_analysis_service.
      // Non-leaf images and failed analyses carry shouldSaveToHistory=false
      // and must never be written to the database.
      final shouldSaveToHistory =
          widget.scanData['shouldSaveToHistory'] as bool? ?? true;

      if (!shouldSaveToHistory) {
        debugPrint('🚫 shouldSaveToHistory=false — skipping database save');
        if (mounted) setState(() => _isAlreadySaved = true);
        return;
      }

      await _checkAndSaveScan();
    } catch (e) {
      debugPrint('Analysis error: $e');
      _leafAnalysis = LeafAnalysisResult(
        isLeaf: true,
        confidence: 50.0,
        reasons: ['Analysis error, defaulting to leaf'],
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingSeverityRemediation = false);
      }
    }
  }

  Future<void> _getSeverityAndRemediation() async {
    try {
      debugPrint('🔍 Getting severity and remediation from service...');

      final severityResult = await _severityIdService.getSeverityAndRemediation(
        diseaseName: widget.scanData['diseaseName']?.toString() ?? '',
        plantName: widget.scanData['plantName']?.toString() ?? '',
        confidence: DataParsers.parseConfidence(widget.scanData['confidence']),
        imagePath: widget.scanData['imagePath'] as String?,
        imageBase64: widget.scanData['imageBase64'] as String?,
      );

      if (severityResult != null) {
        _severity = severityResult['severity']?.toString() ??
            widget.scanData['severity']?.toString() ??
            'None'; // FIX 4: fallback to None not Medium

        final remediationData = severityResult['remediation'];
        _remediation = DataParsers.parseStringToList(remediationData);

        widget.scanData['severity'] = _severity;
        widget.scanData['remediation'] = _remediation;

        debugPrint('✅ Severity: $_severity');
        debugPrint('✅ Remediation count: ${_remediation.length}');
      } else {
        _useFallbackSeverityAndRemediation();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting severity and remediation: $e');
      debugPrint('Stack trace: $stackTrace');
      _useFallbackSeverityAndRemediation();
    }
  }

  void _useFallbackSeverityAndRemediation() {
    // FIX 4: fallback respects healthy plants — don't default to 'Medium'
    final isHealthy = widget.scanData['isHealthy'] as bool? ?? false;
    _severity = widget.scanData['severity']?.toString() ??
        (isHealthy ? 'None' : 'Unknown');
    _remediation = DataParsers.parseStringToList(
      widget.scanData['remediation'] ?? widget.scanData['treatment'],
    );
    debugPrint('⚠️ Using fallback severity and remediation');
  }

  Future<void> _loadJsonData() async {
    try {
      debugPrint('📚 Loading JSON data...');

      final causesFuture =
      rootBundle.loadString('assets/data/disease_causes.json');
      final mappingFuture =
      rootBundle.loadString('assets/data/mapping.json');

      final results = await Future.wait([causesFuture, mappingFuture]);

      _diseaseCauses.addAll(json.decode(results[0]));
      _diseaseMapping.addAll(json.decode(results[1]));

      _extractDiseaseCauses();

      if (mounted) {
        setState(() => _jsonLoaded = true);
      }
    } catch (e) {
      debugPrint('❌ Error loading JSON data: $e');
      if (mounted) {
        setState(() => _jsonLoaded = true);
      }
    }
  }

  void _extractDiseaseCauses() {
    final extractor = DiseaseCauseExtractor(
      diseaseCauses: _diseaseCauses,
      diseaseMapping: _diseaseMapping,
      isLeafImage: _isLeafImage,
      rawLabel: widget.scanData['rawLabel']?.toString(),
      diseaseName: widget.scanData['diseaseName']?.toString(),
      plantName: widget.scanData['plantName']?.toString(),
      confidence: DataParsers.parseConfidence(widget.scanData['confidence']),
      minimumConfidence: ResultScreenConstants.minimumConfidence,
    );

    _diseaseCausesList = extractor.extract();
  }

  Future<void> _checkAndSaveScan() async {
    // FIX 3: Double-check skipSave flag before calling shouldSkipSave
    if (widget.scanData['skipSave'] == true ||
        widget.scanData['shouldSaveToHistory'] == false) {
      debugPrint('📂 Skipping save — flagged as non-saveable');
      if (mounted) setState(() => _isAlreadySaved = true);
      return;
    }

    final shouldSkip =
    await _scanSaveService.shouldSkipSave(widget.scanData);

    if (shouldSkip) {
      debugPrint('📂 Skipping auto-save for existing/advanced scan');
      if (mounted) setState(() => _isAlreadySaved = true);
      return;
    }

    if (_isAlreadySaved || _isSaving) {
      debugPrint('✅ Scan already processed in this session');
      return;
    }

    await _saveScanToDatabase();
  }

  Future<void> _saveScanToDatabase() async {
    setState(() => _isSaving = true);

    try {
      final scanId = _scanSaveService.generateScanId(widget.scanData);

      if (await _scanSaveService.isScanAlreadySaved(scanId)) {
        debugPrint('✅ Scan already exists in database');
        _updateSaveState(false, true);
        return;
      }

      final processedData = await _scanSaveService.processScanData(
        widget.scanData,
        scanId,
        _leafAnalysis,
        _severity,
        _remediation,
      );

      await _scanSaveService.saveScan(
        processedData,
        widget.scanData['imagePath'] as String?,
      );

      debugPrint('✅ Scan saved successfully: $scanId');
      _updateSaveState(false, true);
    } catch (e, stackTrace) {
      debugPrint('❌ Save error: $e\n$stackTrace');
      _updateSaveState(false, false);

      if (!DataParsers.isDuplicateError(e)) {
        _showSaveError();
      }
    }
  }

  void _updateSaveState(bool isSaving, bool isSaved) {
    if (mounted) {
      setState(() {
        _isSaving = isSaving;
        _isAlreadySaved = isSaved;
      });
    }
  }

  void _scheduleAdvancedSearchBanner() {
    _advancedSearchTimer =
        Timer(ResultScreenConstants.advancedSearchDelay, () {
          if (!mounted || !_isLeafImage) return;

          setState(() => _showAdvancedSearchBanner = true);

          _advancedSearchTimer = Timer(
            ResultScreenConstants.advancedSearchDuration,
                () {
              if (mounted) {
                setState(() => _showAdvancedSearchBanner = false);
              }
            },
          );
        });
  }

  void _navigateToAdvancedSearch() {
    setState(() => _showAdvancedSearchBanner = false);
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedSearchScreen(
          originalScanData: widget.scanData,
        ),
      ),
    );
  }

  void _handleBackNavigation() {
    if (_isSaving) return;
    HapticFeedback.lightImpact();

    final previousRoute = widget.scanData['previousRoute'] as String?;
    final fromCapture = widget.scanData['fromCapture'] as bool? ?? false;

    if (fromCapture) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.scan,
            (route) => false,
      );
    } else if (previousRoute != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        previousRoute,
            (route) => false,
      );
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
            (route) => false,
      );
    }
  }

  Future<void> _generatePdfReport() async {
    if (_isGeneratingPdf) return;

    setState(() => _isGeneratingPdf = true);

    final pdfScanData = {
      ...widget.scanData,
      'severity': _severity,
      'remediation': _remediation,
      'symptoms': _diseaseCausesList,
      // FIX 1: Use the already-reconciled plant name from scanData directly.
      // Do NOT call _resolvePlantName() which re-parses rawLabel and can
      // reintroduce the Tomato/Apple mismatch bug.
      'plantName': widget.scanData['plantName']?.toString() ?? 'Unknown Plant',
      'diseaseName': _getDiseaseName(),
      'confidence': widget.scanData['confidence']?.toString() ?? '0',
    };

    await _pdfService.generateAndShowPdf(
      context: context,
      scanData: pdfScanData,
      onError: (msg) {
        if (mounted) {
          setState(() => _isGeneratingPdf = false);
          _showErrorSnackBar(msg);
        }
      },
      onSuccess: (file) async {
        if (!mounted) return;
        setState(() => _isGeneratingPdf = false);
        await _pdfService.showPdfSuccessDialog(context, file);
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _shareScanResult() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.share_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Sharing...'),
        ]),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
    final plantName = widget.scanData['plantName']?.toString() ?? 'Unknown Plant';
    final diseaseName = _getDiseaseName();
    final confidence = widget.scanData['confidence']?.toString() ?? '0';
    final treatment = _remediation.isNotEmpty ? _remediation.first : 'See app for details';
    final shareText = '''🌱 AgriGuard Scan Result
Plant: $plantName
Disease: $diseaseName
Severity: $_severity
Confidence: $confidence%
Treatment: $treatment

Scanned with AgriGuard App''';
    await Share.share(shareText);
  }

  void _showSaveError() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Failed to save scan'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  DiagnosisResult _getDiagnosisResult() {
    return DiagnosisResult.fromScanData({
      ...widget.scanData,
      'severity': _severity,
      'remediation': _remediation,
      // FIX 1: Use scanData's plantName directly — it was already reconciled
      // by plant_analysis_service._reconcilePlantName(). Do not re-derive it
      // from rawLabel here, which would reintroduce the cross-model mismatch.
      'plantName': widget.scanData['plantName']?.toString() ?? 'Unknown Plant',
    });
  }

  // FIX 1: Removed _resolvePlantName() entirely.
  //
  // OLD behaviour:
  //   - Parsed rawLabel (e.g. "Tomato___healthy") → extracted "Tomato"
  //   - Used that name when disease ≠ healthy, overriding the reconciled name
  //   - For Apple with rawLabel="Tomato___healthy" this reverted to "Tomato"
  //
  // NEW behaviour:
  //   - plant_analysis_service._reconcilePlantName() already stored the
  //     correct name in scanData['plantName'] before this screen opens.
  //   - We just read scanData['plantName'] directly everywhere.

  String _getDiseaseName() {
    return widget.scanData['diseaseName']?.toString() ??
        widget.scanData['diagnosis']?.toString() ??
        'Healthy';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSeverityRemediation) {
      return LoadingIndicator(
        message: 'Getting recommendations...',
        subtitle: 'Fetching severity and treatment data',
      );
    }

    final theme = Theme.of(context);
    final diagnosisResult = _getDiagnosisResult();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _handleBackNavigation();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarContent(
          title: 'Analysis Results',
          showBackButton: !_isSaving,
          onBackPressed: _handleBackNavigation,
          actions: [
            GestureDetector(
              onTap: _shareScanResult,
              child: Container(
                width: 38, height: 38,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkCard : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.share_rounded, size: 18, color: AppColors.primary),
              ),
            ),
          ],
        ),
        body: Container(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF0D1117)
              : const Color(0xFFF0F7FF),
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
                  padding: const EdgeInsets.all(
                      ResultScreenConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ImageSection(
                        imagePath: widget.scanData['imagePath'] as String?,
                        imageUrl: widget.scanData['imageUrl'] as String?,
                        imageBase64:
                        widget.scanData['imageBase64'] as String?,
                      ),
                      const SizedBox(height: 20),
                      DiagnosisCard(diagnosisResult: diagnosisResult),
                      const SizedBox(height: 20),
                      AnalysisDetailsCard(scanData: widget.scanData),
                      const SizedBox(height: 20),
                      if (_jsonLoaded)
                        DiseaseCausesCard(causes: _diseaseCausesList),
                      const SizedBox(height: 20),
                      RecommendationsCard(
                        recommendations: diagnosisResult.recommendations,
                      ),
                      const SizedBox(height: 20),
                      if (_isLeafImage) ...[
                        const NextStepsCard(),
                        const SizedBox(height: 20),
                      ],
                      if (_isLeafImage && !_isGuestMode)
                        AdvancedSearchButton(
                          onTap: _navigateToAdvancedSearch,
                        ),
                      // Scan Again button
                      if (_isLeafImage && !_isSaving) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.scan,
                                (route) => route.settings.name == AppRoutes.home,
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Scan Again'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height:
                      ResultScreenConstants.bottomButtonPadding),
                    ],
                  ),
                ),
              ),
              if (_showAdvancedSearchBanner && _isLeafImage && !_isGuestMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 80,
                  child: FloatingAdvancedSearchBanner(
                    onTap: _navigateToAdvancedSearch,
                    onDismiss: () {
                      if (mounted) {
                        setState(
                                () => _showAdvancedSearchBanner = false);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton:
        _isLeafImage && !_isGeneratingPdf && !_isSaving
            ? Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PdfFloatingButton(
            onPressed: _generatePdfReport,
            isGenerating: _isGeneratingPdf,
          ),
        )
            : null,
        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}