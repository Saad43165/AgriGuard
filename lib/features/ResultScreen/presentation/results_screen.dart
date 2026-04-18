import 'dart:convert';
import 'dart:io';
import 'package:agriguard_fyp/features/ResultScreen/presentation/components/image_section.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/components/loading_indicator.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/service/scan_save_service.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/utils/constants.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/utils/data_parsers.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/utils/disease_cause_extractor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../auth/Login_Screen/services/guest_service.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/repositories/scan_repository.dart';
import '../../../../core/services/severity_id_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/widgets/app_themes.dart';
import '../../advance_search_screen/advanced_search_screen.dart';
import 'components/disease_cause_card.dart' show DiseaseCausesCard;
import 'models/diagnosis_result.dart';
import 'models/leaf_analysis_result.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> scanData;
  const ResultsScreen({required this.scanData, super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
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

  @override
  void initState() {
    super.initState();
    _initializeGuestMode();
    _initializeServices();
    _loadJsonData();
    _analyzeAndSave();
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
      if (confidence < 40.0) {
        debugPrint('⚠️ Not saving — confidence too low (${confidence.toStringAsFixed(1)}%)');
        if (mounted) setState(() => _isAlreadySaved = true);
        return;
      }

      await _checkAndSaveScan();
    } catch (e) {
      debugPrint('Analysis error: $e');
      _leafAnalysis = LeafAnalysisResult(isLeaf: true, confidence: 50.0, reasons: ['Error']);
    } finally {
      if (mounted) setState(() => _isLoadingSeverity = false);
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
    final plant = widget.scanData['plantName']?.toString() ?? 'Unknown Plant';
    final disease = widget.scanData['diseaseName']?.toString() ?? (t.isUrdu ? 'صحت مند' : 'Healthy');
    await Share.share('🌱 AgriGuard\nPlant: $plant\nDisease: $disease\nSeverity: $_severity\n\nScanned with AgriGuard');
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
      return _NonPlantScreen(
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
    final sheetBg = isDark ? AppColors.darkCard : Colors.white;
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
                          child: _CircleBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: _handleBack),
                        ),
                        // Share only on right
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 12,
                          right: 16,
                          child: _CircleBtn(icon: Icons.share_rounded, onTap: _share),
                        ),
                      ],
                    ),
                  ),
                ),

                // White content sheet
                SliverToBoxAdapter(
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
                            diagnosisResult.scientificName != null
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
                          _Chip(icon: '🌿', label: diagnosisResult.isHealthy ? t.isUrdu ? 'صحت مند' : 'Healthy' : _severity, isDark: isDark),
                          _Chip(icon: '📊', label: '${confidence.toStringAsFixed(0)}% Confidence', isDark: isDark),
                          if (!diagnosisResult.isHealthy)
                            _Chip(icon: '⚠️', label: t.translateDisease(diagnosisResult.disease), isDark: isDark),
                          if (_remediation.isNotEmpty)
                            _Chip(icon: '💊', label: t.isUrdu ? 'علاج دستیاب' : 'Treatment Available', isDark: isDark),
                        ]),

                        // Alerts
                        if (isUnknown && _isLeafImage) ...[
                          const SizedBox(height: 14),
                          _AlertRow(icon: Icons.help_outline_rounded,
                              message: t.isUrdu ? 'پودے کی شناخت نہیں ہوئی — بہتر نتائج کے لیے Advanced AI آزمائیں' : 'Plant not identified — try Advanced AI for better results',
                              color: AppColors.info, isDark: isDark),
                        ],

                        // Treatment
                        if (_isLeafImage && _remediation.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SectionHeader(icon: Icons.healing_rounded, title: t.get('treatment_plan'), isDark: isDark),
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
                          _SectionHeader(icon: Icons.biotech_rounded, title: t.get('disease_causes'), isDark: isDark),
                          const SizedBox(height: 8),
                          DiseaseCausesCard(causes: _diseaseCausesList),
                        ],
                      ],
                    ),
                  ),
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

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String icon, label;
  final bool isDark;
  const _Chip({required this.icon, required this.label, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkBg : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE8E8E8)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkSubtext : const Color(0xFF4A5568))),
    ]),
  );
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final bool isDark;
  const _AlertRow({required this.icon, required this.message, required this.color, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: TextStyle(fontSize: 12,
          color: isDark ? AppColors.darkSubtext : const Color(0xFF4A5568), height: 1.4))),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  const _SectionHeader({required this.icon, required this.title, required this.isDark});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.primary, size: 16),
    const SizedBox(width: 8),
    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E))),
  ]);
}




// ── Dedicated non-plant screen ────────────────────────────────────────────────
class _NonPlantScreen extends StatelessWidget {
  final String? imagePath;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  const _NonPlantScreen({this.imagePath, required this.isDark, required this.onBack, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context, listen: false);
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: cardBg, shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16,
                      color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)),
              ),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imagePath != null)
                    Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 2)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(File(imagePath!), fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.error.withValues(alpha: 0.08),
                              child: const Icon(Icons.image_not_supported_rounded, size: 48, color: AppColors.error))),
                      ),
                    )
                  else
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.image_not_supported_rounded, size: 52, color: AppColors.error),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    t.isUrdu ? 'پودے کا پتہ نہیں ملا' : 'No Plant Detected',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.isUrdu
                        ? 'یہ تصویر پودے کے پتے کی نہیں لگتی۔ بہتر نتائج کے لیے نیچے دی گئی ہدایات پر عمل کریں۔'
                        : 'This image doesn\'t appear to be a plant leaf. Follow the tips below for better results.',
                    style: TextStyle(fontSize: 14, color: captionColor, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    child: Column(children: [
                      _Tip(icon: Icons.center_focus_strong_rounded,
                          text: t.isUrdu ? 'پتے کو فریم میں بھریں' : 'Fill the frame with a single leaf', isDark: isDark),
                      const SizedBox(height: 10),
                      _Tip(icon: Icons.wb_sunny_rounded,
                          text: t.isUrdu ? 'اچھی روشنی میں تصویر لیں' : 'Use good natural lighting', isDark: isDark),
                      const SizedBox(height: 10),
                      _Tip(icon: Icons.blur_off_rounded,
                          text: t.isUrdu ? 'واضح اور فوکس تصویر لیں' : 'Keep the image sharp and in focus', isDark: isDark),
                      const SizedBox(height: 10),
                      _Tip(icon: Icons.eco_rounded,
                          text: t.isUrdu ? 'صرف پودوں کے پتوں کی تصویر لیں' : 'Only scan plant leaves', isDark: isDark),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(t.isUrdu ? 'دوبارہ اسکین کریں' : 'Scan Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _Tip({required this.icon, required this.text, required this.isDark});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: AppColors.primary, size: 16)),
    const SizedBox(width: 12),
    Expanded(child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkSubtext : const Color(0xFF4A5568)))),
  ]);
}
