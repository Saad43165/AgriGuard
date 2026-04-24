import 'dart:convert';
import 'dart:io';
import 'package:agriguard_fyp/features/result_screen/presentation/components/image_section.dart';
import 'package:agriguard_fyp/features/result_screen/presentation/components/loading_indicator.dart';
import 'package:agriguard_fyp/features/result_screen/presentation/service/scan_save_service.dart';
import 'package:agriguard_fyp/features/result_screen/presentation/utils/constants.dart';
import 'package:agriguard_fyp/features/result_screen/presentation/utils/data_parsers.dart';
import 'package:agriguard_fyp/features/result_screen/presentation/utils/disease_cause_extractor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../auth/login/services/guest_service.dart';
import 'package:agriguard_fyp/core/constants/app_routes.dart';
import 'package:agriguard_fyp/core/repositories/scan_repository.dart';
import 'package:agriguard_fyp/core/services/severity_id_service.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import '../../advance_search_screen/advanced_search_screen.dart';
import 'components/disease_cause_card.dart' show DiseaseCausesCard;
import 'components/non_plant_screen.dart';
import 'models/diagnosis_result.dart';
import 'models/leaf_analysis_result.dart';
import 'widgets/result_widgets.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> scanData;
  const ResultsScreen({required this.scanData, super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with TickerProviderStateMixin {
  bool _isSaving = false;
  bool _isAlreadySaved = false;
  bool _jsonLoaded = false;

  LeafAnalysisResult? _leafAnalysis;
  bool get _isLeafImage => _leafAnalysis?.isLeaf ?? (widget.scanData['isLeaf'] as bool? ?? true);

  final Map<String, dynamic> _diseaseCauses = {};
  final Map<String, dynamic> _diseaseMapping = {};
  List<dynamic> _diseaseCausesList = [];

  String _severity = 'None';
  List<String> _remediation = [];
  List<String> _remediationUr = [];
  bool _isLoadingSeverity = false;

  late final ScanRepository _scanRepository;
  late final SeverityIdService _severityIdService;
  late final ScanSaveService _scanSaveService;
  final GuestService _guestService = GuestService();
  bool _isGuestMode = false;

  // Vibe: slide-up animation for content
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _initializeGuestMode();
    _initializeServices();
    _loadJsonData();
    _analyzeAndSave();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeGuestMode() async {
    await _guestService.initialize();
    if (mounted) setState(() => _isGuestMode = _guestService.isGuestMode);
  }

  void _initializeServices() {
    _scanRepository = ScanRepository();
    _severityIdService = SeverityIdService();
    _scanSaveService = ScanSaveService(scanRepository: _scanRepository);
  }

  Future<void> _analyzeAndSave() async {
    setState(() => _isLoadingSeverity = true);
    try {
      final leafFromScan = widget.scanData['leafAnalysis'];
      if (leafFromScan is Map<String, dynamic>) {
        _leafAnalysis = LeafAnalysisResult.fromJson(leafFromScan);
      } else {
        final isLeaf = widget.scanData['isLeaf'] as bool? ?? true;
        final leafConf = (widget.scanData['leafConfidence'] as num?)?.toDouble() ?? 50.0;
        _leafAnalysis = LeafAnalysisResult(
          isLeaf: isLeaf, confidence: leafConf,
          reasons: [isLeaf ? 'Leaf detected' : 'Not a leaf'],
          details: widget.scanData['leafDetectionDetails'] as Map<String, dynamic>?,
        );
      }
      if (_leafAnalysis!.isLeaf) {
        await _getSeverityAndRemediation();
      } else {
        _severity = 'N/A';
        _remediation = DataParsers.parseStringToList(widget.scanData['remediation'] ?? widget.scanData['treatment']);
      }
      final shouldSave = widget.scanData['shouldSaveToHistory'] as bool? ?? true;
      if (!shouldSave) { if (mounted) setState(() => _isAlreadySaved = true); return; }

      // Don't save non-leaf images or very low confidence scans to history
      final confidence = DataParsers.parseConfidence(widget.scanData['confidence']);
      final isLeafImage = _leafAnalysis?.isLeaf ?? true;
      final isNonLeaf = !isLeafImage ||
          widget.scanData['plantName']?.toString() == 'Non-Plant Image' ||
          widget.scanData['diseaseName']?.toString() == 'Image Not Recognized';
      if (isNonLeaf) {
        debugPrint('⚠️ Not saving — non-leaf image');
        if (mounted) setState(() => _isAlreadySaved = true);
        return;
      }
      if (confidence < 50.0) {
        debugPrint('⚠️ Not saving — confidence too low (${confidence.toStringAsFixed(1)}%)');
        if (mounted) setState(() => _isAlreadySaved = true);
        return;
      }

      // Also block unknown plant scans
      final plantName = widget.scanData['plantName']?.toString() ?? '';
      if (plantName.isEmpty || plantName == 'Unknown Plant') {
        debugPrint('⚠️ Not saving — unknown plant');
        if (mounted) setState(() => _isAlreadySaved = true);
        return;
      }

      await _checkAndSaveScan();
    } catch (e) {
      debugPrint('Analysis error: $e');
      _leafAnalysis = LeafAnalysisResult(isLeaf: true, confidence: 50.0, reasons: ['Error']);
    } finally {
      if (mounted) {
        setState(() => _isLoadingSeverity = false);
        _slideCtrl.forward(); // trigger slide-up animation
      }
    }
  }

  Future<void> _getSeverityAndRemediation() async {
    try {
      final result = await _severityIdService.getSeverityAndRemediation(
        diseaseName: widget.scanData['diseaseName']?.toString() ?? '',
        plantName: widget.scanData['plantName']?.toString() ?? '',
        confidence: DataParsers.parseConfidence(widget.scanData['confidence']),
        imagePath: widget.scanData['imagePath'] as String?,
        imageBase64: widget.scanData['imageBase64'] as String?,
      );
      if (result != null) {
        _severity = result['severity']?.toString() ?? widget.scanData['severity']?.toString() ?? 'None';
        _remediation = DataParsers.parseStringToList(result['remediation']);
        _remediationUr = DataParsers.parseStringToList(result['remediation_ur'] ?? result['remediation']);
        widget.scanData['severity'] = _severity;
        widget.scanData['remediation'] = _remediation;
      } else { _useFallback(); }
    } catch (_) { _useFallback(); }
  }

  void _useFallback() {
    final isHealthy = widget.scanData['isHealthy'] as bool? ?? false;
    _severity = widget.scanData['severity']?.toString() ?? (isHealthy ? 'None' : 'Unknown');
    _remediation = DataParsers.parseStringToList(widget.scanData['remediation'] ?? widget.scanData['treatment']);
  }

  Future<void> _loadJsonData() async {
    try {
      final r = await Future.wait([
        rootBundle.loadString('assets/data/disease_causes.json'),
        rootBundle.loadString('assets/data/mapping.json'),
      ]);
      _diseaseCauses.addAll(json.decode(r[0]));
      _diseaseMapping.addAll(json.decode(r[1]));
      _extractDiseaseCauses();
      if (mounted) setState(() => _jsonLoaded = true);
    } catch (_) { if (mounted) setState(() => _jsonLoaded = true); }
  }

  void _extractDiseaseCauses() {
    _diseaseCausesList = DiseaseCauseExtractor(
      diseaseCauses: _diseaseCauses, diseaseMapping: _diseaseMapping,
      isLeafImage: _isLeafImage,
      rawLabel: widget.scanData['rawLabel']?.toString(),
      diseaseName: widget.scanData['diseaseName']?.toString(),
      plantName: widget.scanData['plantName']?.toString(),
      confidence: DataParsers.parseConfidence(widget.scanData['confidence']),
      minimumConfidence: ResultScreenConstants.minimumConfidence,
    ).extract();
  }

  Future<void> _checkAndSaveScan() async {
    if (widget.scanData['skipSave'] == true || widget.scanData['shouldSaveToHistory'] == false) {
      if (mounted) setState(() => _isAlreadySaved = true); return;
    }
    if (await _scanSaveService.shouldSkipSave(widget.scanData)) {
      if (mounted) setState(() => _isAlreadySaved = true); return;
    }
    if (_isAlreadySaved || _isSaving) return;
    await _saveScan();
  }

  Future<void> _saveScan() async {
    setState(() => _isSaving = true);
    try {
      final scanId = _scanSaveService.generateScanId(widget.scanData);
      if (await _scanSaveService.isScanAlreadySaved(scanId)) { _updateSaveState(false, true); return; }
      final processed = await _scanSaveService.processScanData(widget.scanData, scanId, _leafAnalysis, _severity, _remediation);
      await _scanSaveService.saveScan(processed, widget.scanData['imagePath'] as String?);
      _updateSaveState(false, true);
    } catch (e) {
      debugPrint('Save error: $e');
      _updateSaveState(false, false);
    } finally {
      if (mounted && _isSaving) setState(() => _isSaving = false);
    }
  }

  void _updateSaveState(bool saving, bool saved) {
    if (mounted) setState(() { _isSaving = saving; _isAlreadySaved = saved; });
  }

  void _goAdvanced() {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AdvancedSearchScreen(originalScanData: widget.scanData),
    ));
  }

  void _handleBack() {
    if (_isSaving) return;
    HapticFeedback.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    }
  }

  Future<void> _share() async {
    final t = Provider.of<TranslationService>(context, listen: false);
    final plant = t.translatePlant(widget.scanData['plantName']?.toString() ?? 'Unknown Plant');
    final disease = t.translateDisease(widget.scanData['diseaseName']?.toString() ?? (t.isUrdu ? 'صحت مند' : 'Healthy'));
    final severityLabel = t.translateSeverity(_severity);
    await Share.share('🌱 AgriGuard\nPlant: $plant\nDisease: $disease\nSeverity: $severityLabel\n\nScanned with AgriGuard');
  }

  DiagnosisResult _getDiagnosisResult() => DiagnosisResult.fromScanData({
    ...widget.scanData, 'severity': _severity, 'remediation': _remediation,
    'plantName': widget.scanData['plantName']?.toString() ?? 'Unknown Plant',
  });

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSeverity) {
      return const LoadingIndicator(message: 'Analyzing results...', subtitle: 'Getting severity and treatment data');
    }

    // ── Non-plant image — show dedicated screen ────────────────────────────
    if (!_isLeafImage) {
      return NonPlantScreen(
        imagePath: widget.scanData['imagePath'] as String?,
        isDark: Theme.of(context).brightness == Brightness.dark,
        onBack: _handleBack,
        onRetry: () => Navigator.of(context).pop(),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diagnosisResult = _getDiagnosisResult();
    final t = Provider.of<TranslationService>(context);
    final confidence = DataParsers.parseConfidence(widget.scanData['confidence']);
    final isUnknown = widget.scanData['isUnknown'] as bool? ?? false;

    // ── Ambient color based on health status ──────────────────────────────
    Color sheetBg;
    if (isDark) {
      sheetBg = AppColors.darkCard;
    } else if (isUnknown) {
      sheetBg = Colors.white;
    } else if (diagnosisResult.isHealthy) {
      sheetBg = const Color(0xFFF0FFF4); // subtle green tint
    } else {
      sheetBg = const Color(0xFFFFF8F8); // subtle red tint
    }

    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: Stack(
          children: [
            // ── Scrollable: image scrolls away, content stays ──────────
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Image as collapsible header — scrolls away
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.45,
                  pinned: false,
                  floating: false,
                  backgroundColor: Colors.black,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        ImageSection(
                          imagePath: widget.scanData['imagePath'] as String?,
                          imageUrl: widget.scanData['imageUrl'] as String?,
                          imageBase64: widget.scanData['imageBase64'] as String?,
                        ),
                        // Fade into sheet at bottom
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [sheetBg, Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                        // Back button only — no duplicate close
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 12,
                          left: 16,
                          child: ResultCircleBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: _handleBack),
                        ),
                        // Share only on right
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 12,
                          right: 16,
                          child: ResultCircleBtn(icon: Icons.share_rounded, onTap: _share),
                        ),
                      ],
                    ),
                  ),
                ),

                // White content sheet
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Container(
                    color: sheetBg,
                    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Plant name
                        Text(
                          t.translatePlant(diagnosisResult.plantName),
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                              color: textColor, letterSpacing: -0.5, height: 1.1),
                        ),
                        const SizedBox(height: 4),

                        // Type • disease
                        Row(children: [
                          Text(
                            diagnosisResult.isHealthy ? 'Plant' : 'Disease',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                          Text(
                            (diagnosisResult.scientificName != null && diagnosisResult.scientificName!.isNotEmpty)
                                ? '  •  ${diagnosisResult.scientificName}'
                                : '  •  ${t.translateDisease(diagnosisResult.disease)}',
                            style: TextStyle(fontSize: 14, color: captionColor),
                          ),
                        ]),
                        const SizedBox(height: 8),

                        // Not your plant
                        if (!_isGuestMode)
                          GestureDetector(
                            onTap: _goAdvanced,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(t.isUrdu ? 'آپ کا پودا نہیں؟' : 'Not your plant?',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                    color: Colors.red.shade600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.red.shade600)),
                            ),
                          ),
                        const SizedBox(height: 14),

                        // Chips
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          ResultChip(icon: '🌿', label: diagnosisResult.isHealthy ? (t.isUrdu ? 'صحت مند' : 'Healthy') : t.translateSeverity(_severity), isDark: isDark),
                          ResultChip(icon: '📊', label: '${confidence.toStringAsFixed(0)}% ${t.isUrdu ? 'اعتماد' : 'Confidence'}', isDark: isDark),
                          if (!diagnosisResult.isHealthy)
                            ResultChip(icon: '⚠️', label: t.translateDisease(diagnosisResult.disease), isDark: isDark),
                          if (_remediation.isNotEmpty)
                            ResultChip(icon: '💊', label: t.isUrdu ? 'علاج دستیاب' : 'Treatment Available', isDark: isDark),
                        ]),

                        // Alerts
                        if (isUnknown && _isLeafImage) ...[
                          const SizedBox(height: 14),
                          ResultAlertRow(icon: Icons.help_outline_rounded,
                              message: t.isUrdu ? 'پودے کی شناخت نہیں ہوئی — بہتر نتائج کے لیے Advanced AI آزمائیں' : 'Plant not identified — try Advanced AI for better results',
                              color: AppColors.info, isDark: isDark),
                        ],

                        // Treatment
                        if (_isLeafImage && _remediation.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ResultSectionHeader(icon: Icons.healing_rounded, title: t.get('treatment_plan'), isDark: isDark),
                          const SizedBox(height: 8),
                          ...(() {
                            final list = t.isUrdu && _remediationUr.isNotEmpty ? _remediationUr : _remediation;
                            return list.take(3).map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(margin: const EdgeInsets.only(top: 6), width: 6, height: 6,
                                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(r, style: TextStyle(fontSize: 13,
                                    color: isDark ? AppColors.darkSubtext : const Color(0xFF4A5568), height: 1.5))),
                              ]),
                            ));
                          })(),
                        ],

                        // Disease causes
                        if (_isLeafImage && _jsonLoaded && _diseaseCausesList.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ResultSectionHeader(icon: Icons.biotech_rounded, title: t.get('disease_causes'), isDark: isDark),
                          const SizedBox(height: 8),
                          DiseaseCausesCard(causes: _diseaseCausesList),
                        ],
                      ],
                    ),
                  ),
                    ), // SlideTransition
                  ), // FadeTransition
                ),
              ],
            ),

            // ── Fixed bottom bar ───────────────────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: sheetBg,
                  border: Border(top: BorderSide(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE))),
                ),
                child: Row(children: [
                  // Camera — opens camera to scan again
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                      // The parent will handle opening camera via navbar
                    },
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBg : const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE8E8E8)),
                      ),
                      child: Icon(Icons.camera_alt_outlined,
                          color: isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E), size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Advanced AI
                  Expanded(
                    child: GestureDetector(
                      onTap: _goAdvanced,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(50)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(t.isUrdu ? 'ایڈوانسڈ AI' : 'Advanced AI', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            if (false)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Generating PDF…', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ])),
              ),
          ],
        ),
      ),
    );
  }
}







