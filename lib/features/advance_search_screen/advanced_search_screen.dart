import 'dart:io';

import 'package:agriguard_fyp/features/advance_search_screen/widgets/AdvancedBottomPanel.dart';
import 'package:agriguard_fyp/features/advance_search_screen/widgets/AdvancedTopImageSection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import '../advance_result_screen/advanced_result_screen.dart';
import '../capture/presentation/widgets/processing_overlay.dart';
import 'models/advanced_option.dart';
import 'service/advanced_search_service.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final Map<String, dynamic> originalScanData;
  const AdvancedSearchScreen({super.key, required this.originalScanData});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;
  bool _isCheckingApis = true;
  int _selectedIndex = 0;
  Map<String, dynamic>? _apiStatus;
  final AdvancedSearchService _searchService = AdvancedSearchService();

static const _options = [
    AdvancedOption(
      'Plant.id',
      'Deep plant & disease identification',
      Icons.park_outlined,
      'Plant.id',
      '3–5s',
    ),
    AdvancedOption(
      'AI Advisor',
      'Expert agricultural advice & treatment',
      Icons.chat_bubble_outline_rounded,
      'Groq',
      '2–4s',
    ),
  ];

  static const _optionsUr = [
    AdvancedOption(
      'پلانٹ ایکسپرٹ',
      'گہری پودوں اور بیماریوں کی شناخت',
      Icons.park_outlined,
      'Plant.id',
      '3–5s',
    ),
    AdvancedOption(
      'AI مشیر',
      'ماہرانہ زرعی مشورہ اور علاج',
      Icons.chat_bubble_outline_rounded,
      'Groq',
      '2–4s',
    ),
  ];

  List<AdvancedOption> _localizedOptions(bool isUrdu) =>
      isUrdu ? _optionsUr : _options;

  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _checkApis();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkApis() async {
    try {
      final s = await _searchService.testAllApis();
      if (!mounted) return;
      setState(() {
        _apiStatus = s;
        _isCheckingApis = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiStatus = {};
        _isCheckingApis = false;
      });
    }
  }

  bool _available(int i) {
    if (_apiStatus == null) return true;
    const keys = ['plantId', 'groq'];
    final v = _apiStatus![keys[i]];
    return v is Map ? (v['available'] == true) : true;
  }

  Future<void> _start(TranslationService t) async {
    if (_isAnalyzing) return;

    final imagePath = widget.originalScanData['imagePath'] as String?;
    if (imagePath == null || !File(imagePath).existsSync()) {
      _err(
        t.isUrdu
            ? 'تصویر نہیں ملی۔ براہ کرم واپس جا کر دوبارہ تصویر لیں۔'
            : 'Image not found. Please go back and retake the photo.',
      );
      return;
    }

    if (!_available(_selectedIndex)) {
      _err(
        t.isUrdu
            ? 'یہ سروس آف لائن ہے۔ براہ کرم دوسرا آپشن منتخب کریں۔'
            : 'This service is offline. Please select another option.',
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final file = File(imagePath);
      final tag = _options[_selectedIndex].tag;
      Map<String, dynamic> result;

   if (tag == 'Plant.id') {
        result = await _searchService.analyzeWithPlantId(file);
      } else {
        result = await _searchService.analyzePlant(file, inUrdu: t.isUrdu);      }

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      if (result['success'] == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdvancedResultsScreen(
              analysisResult: result,
              originalScanData: widget.originalScanData,
            ),
          ),
        );
      } else {
        _err(
          result['message'] ??
              result['error'] ??
              (t.isUrdu ? 'تجزیہ ناکام ہوا۔' : 'Analysis failed.'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      _err(t.isUrdu ? 'خرابی: $e' : 'Error: $e');
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imagePath = widget.originalScanData['imagePath'] as String?;
    final localOpts = _localizedOptions(t.isUrdu);

    final sheetBg = isDark ? AppColors.darkSurface : Colors.white;
    final sheetBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    // Fade overlay colors (image -> sheet)
    final fadeStart = Colors.transparent;
    final fadeEnd = sheetBg; // match exactly so it blends

    return PopScope(
      canPop: !_isAnalyzing,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Column(
              children: [
                // ── Top image + subtle fade overlay ───────────────────────
                Expanded(
                  flex: 40,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AdvancedTopImageSection(imagePath: imagePath),
                      ),

                      // Subtle gradient fade at the bottom of the image
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 90, // tweak 70-120 depending on taste
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  fadeStart,
                                  fadeEnd.withValues(alpha: 0.90),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom sheet panel ────────────────────────────────────
                Expanded(
                  flex: 60,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: sheetBg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border.all(
                        color: sheetBorder.withValues(alpha: 0.9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 22),
                        Container(
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: AdvancedBottomPanel(
                            isDark: isDark,
                            isCheckingApis: _isCheckingApis,
                            isAnalyzing: _isAnalyzing,
                            selectedIndex: _selectedIndex,
                            options: localOpts,
                            isOptionAvailable: _available,
                            onSelectOption: (i) => setState(() => _selectedIndex = i),
                            onAnalyze: () => _start(t),
                            analyzeLabel: _isAnalyzing
                                ? (t.isUrdu ? 'تجزیہ ہو رہا ہے…' : 'Analyzing…')
                                : (t.isUrdu
                                ? '${localOpts[_selectedIndex].title} سے تجزیہ کریں'
                                : 'Analyze with ${_options[_selectedIndex].title}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Back button ─────────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: GestureDetector(
                onTap: _isAnalyzing ? null : () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

            // ── Processing overlay ──────────────────────────────────────
            if (_isAnalyzing)
              Positioned.fill(
                child: ProcessingOverlay(
                  selectedMethod: _options[_selectedIndex].tag,
                  isProcessing: _isAnalyzing,
                  isGuestMode: false,
                  remainingScans: 0,
                  pulseAnimation: _shimmerCtrl,
                  processingMessage: t.isUrdu
                      ? '${localOpts[_selectedIndex].title} سے تجزیہ ہو رہا ہے…'
                      : 'Analyzing with ${_options[_selectedIndex].title}…',
                  modelStatuses: const {},
                  onCancel: () {},
                  imagePath: imagePath,
                ),
              ),
          ],
        ),
      ),
    );
  }
}