import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import '../advance_result_screen/advanced_result_screen.dart';
import '../capture/presentation/components/processing_overlay.dart';
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
  int _selectedIndex = 2; // default Groq
  Map<String, dynamic>? _apiStatus;
  final AdvancedSearchService _searchService = AdvancedSearchService();

  static const _options = [
    _Option('Disease Scanner', 'Identifies plant diseases from photo',
        CupertinoIcons.leaf_arrow_circlepath, 'Roboflow', '3–6s'),
    _Option('Plant Expert', 'Deep plant & disease identification',
        CupertinoIcons.tree, 'Plant.id', '3–5s'),
    _Option('AI Advisor', 'Get expert farming advice & treatment',
        CupertinoIcons.chat_bubble_text, 'Groq', '2–4s'),
  ];

  static const _optionsUr = [
    _Option('ڈیزیز اسکینر', 'تصویر سے پودوں کی بیماریاں شناخت کرتا ہے',
        CupertinoIcons.leaf_arrow_circlepath, 'Roboflow', '3–6s'),
    _Option('پلانٹ ایکسپرٹ', 'گہری پودوں اور بیماریوں کی شناخت',
        CupertinoIcons.tree, 'Plant.id', '3–5s'),
    _Option('AI مشیر', 'ماہرانہ زرعی مشورہ اور علاج',
        CupertinoIcons.chat_bubble_text, 'Groq', '2–4s'),
  ];

  List<_Option> _localizedOptions(bool isUrdu) =>
      isUrdu ? _optionsUr : _options;

  // Tag labels for each option (always English for API matching)
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
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
      if (mounted) {
        setState(() {
          _apiStatus = s;
          _isCheckingApis = false;
          if (!_available(_selectedIndex)) {
            for (int i = 0; i < _options.length; i++) {
              if (_available(i)) {
                _selectedIndex = i;
                break;
              }
            }
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() { _apiStatus = {}; _isCheckingApis = false; });
    }
  }

  bool _available(int i) {
    if (i == 0) return true;
    if (_apiStatus == null) return true;
    final keys = ['huggingface', 'plantId', 'groq'];
    final v = _apiStatus![keys[i]];
    return v is Map ? (v['available'] == true) : false;
  }

  Future<void> _start(TranslationService t) async {
    if (_isAnalyzing) return;
    final imagePath = widget.originalScanData['imagePath'] as String?;
    if (imagePath == null || !File(imagePath).existsSync()) {
      _err(t.isUrdu
          ? 'تصویر نہیں ملی۔ براہ کرم واپس جا کر دوبارہ تصویر لیں۔'
          : 'Image not found. Please go back and retake the photo.');
      return;
    }
    if (!_available(_selectedIndex)) {
      _err(t.isUrdu
          ? 'یہ سروس آف لائن ہے۔ براہ کرم دوسرا آپشن منتخب کریں۔'
          : 'This service is offline. Please select another option.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isAnalyzing = true);
    try {
      final f = File(imagePath);
      final tag = _options[_selectedIndex].tag;
      Map<String, dynamic> result;
      if (tag == 'Roboflow') {
        result = await _searchService.analyzeWithHuggingFace(f);
      } else if (tag == 'Plant.id') {
        result = await _searchService.analyzeWithPlantId(f);
      } else {
        result = await _searchService.analyzePlant(f);
      }
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      if (result['success'] == true) {
        HapticFeedback.lightImpact();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdvancedResultsScreen(
              analysisResult: result,
              originalScanData: widget.originalScanData,
            ),
          ),
        );
      } else if (result['isNonLeaf'] == true) {
        _err(t.isUrdu
            ? 'یہ پودے کے پتے کی تصویر نہیں ہے۔ براہ کرم پتے کی واضح تصویر لیں۔'
            : 'This doesn\'t appear to be a plant leaf. Please take a clear photo of a leaf.');
      } else {
        _err(result['message'] ??
            result['error'] ??
            (t.isUrdu ? 'تجزیہ ناکام ہوا۔' : 'Analysis failed.'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _err(t.isUrdu ? 'خرابی: $e' : 'Error: $e');
      }
    }
  }

  void _err(String msg) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(CupertinoIcons.exclamationmark_circle,
            color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // ── FIX: listen: TRUE so entire build() re-runs on language toggle ──
    final t = Provider.of<TranslationService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final imagePath = widget.originalScanData['imagePath'] as String?;
    final localOpts = _localizedOptions(t.isUrdu);

    return PopScope(
      canPop: !_isAnalyzing,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Column(children: [
            // ── Image — top 42% ──────────────────────────────────────
            Expanded(
              flex: 42,
              child: Stack(fit: StackFit.expand, children: [
                // Image
                if (imagePath != null && File(imagePath).existsSync())
                  Image.file(File(imagePath), fit: BoxFit.cover)
                else
                  Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Center(
                        child: Icon(CupertinoIcons.photo,
                            size: 64, color: AppColors.primary)),
                  ),

                // Gradient fade bottom
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [cardBg, Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // ── Back button ───────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  child: GestureDetector(
                    onTap: _isAnalyzing ? null : () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(CupertinoIcons.back,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),

                // ── Lang toggle — Consumer so toggle btn always works ─
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: Consumer<TranslationService>(
                    builder: (_, ts, __) => GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ts.toggleLanguage();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.translate_rounded,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            ts.isUrdu ? 'EN' : 'اردو',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),

                // ── AI badge on image ─────────────────────────────
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(CupertinoIcons.sparkles,
                          color: AppColors.primary, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        t.isUrdu ? 'ایڈوانسڈ AI' : 'Advanced AI',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),

            // ── Bottom panel — 58% ───────────────────────────────────
            Expanded(
              flex: 58,
              child: Container(
                color: cardBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.isUrdu ? 'ایڈوانسڈ AI تجزیہ' : 'Advanced AI Analysis',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t.isUrdu
                                    ? 'گہری پودوں کی تشخیص کے لیے طریقہ منتخب کریں'
                                    : 'Choose an AI method for deeper plant diagnosis',
                                style: TextStyle(
                                    fontSize: 12.5, color: captionColor),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),

                    Divider(
                        color: borderColor, height: 1,
                        indent: 20, endIndent: 20),
                    const SizedBox(height: 12),

                    // Options or Loading
                    Expanded(
                      child: _isCheckingApis
                          ? _buildCheckingApis(captionColor, textColor)
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: List.generate(
                                  _options.length,
                                  (i) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: _OptionCard(
                                      option: localOpts[i],
                                      isSelected: _selectedIndex == i,
                                      isAvailable: _available(i),
                                      isDark: isDark,
                                      index: i,
                                      onTap: _available(i) && !_isAnalyzing
                                          ? () => setState(
                                              () => _selectedIndex = i)
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),

                    // Analyze button
                    if (!_isCheckingApis)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            MediaQuery.of(context).padding.bottom + 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isAnalyzing ? null : () => _start(t),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.4),
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isAnalyzing
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        t.isUrdu
                                            ? 'تجزیہ ہو رہا ہے…'
                                            : 'Analyzing…',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(CupertinoIcons.sparkles,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        t.isUrdu
                                            ? '${localOpts[_selectedIndex].title} سے تجزیہ کریں'
                                            : 'Analyze with ${_options[_selectedIndex].title}',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ]),

          // ── Analyzing overlay ─────────────────────────────────────
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
                onCancel: () {}, // No cancellation allowed during advanced API call
                imagePath: imagePath,
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildCheckingApis(Color captionColor, Color textColor) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
                strokeCap: StrokeCap.round),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          Provider.of<TranslationService>(context, listen: false).isUrdu
              ? 'سروسز چیک ہو رہی ہیں…'
              : 'Checking services…',
          style: TextStyle(
              fontSize: 13, color: captionColor, fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _Option {
  final String title, subtitle, tag, duration;
  final IconData icon;
  const _Option(this.title, this.subtitle, this.icon, this.tag, this.duration);
}

// ── Option Card ───────────────────────────────────────────────────────────────
class _OptionCard extends StatelessWidget {
  final _Option option;
  final bool isSelected, isAvailable, isDark;
  final int index;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.isAvailable,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  static const _tagColors = [
    Color(0xFF3B82F6), // HuggingFace — blue
    Color(0xFF10B981), // Plant.id — green
    AppColors.secondary, // Groq — teal
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final accentColor = _tagColors[index];

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(children: [
          // Icon box
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.14)
                  : (isDark
                      ? AppColors.darkBg
                      : const Color(0xFFF5F7F5)),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.3)
                    : (isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
              ),
            ),
            child: Icon(option.icon,
                color: isSelected ? accentColor : captionColor, size: 20),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text(option.title,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isAvailable ? textColor : captionColor)),
                if (!isAvailable) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Offline',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error)),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(option.subtitle,
                  style: TextStyle(
                      fontSize: 11.5, color: captionColor, height: 1.3)),
              const SizedBox(height: 5),
              // Tag pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(option.tag,
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor)),
              ),
            ]),
          ),

          const SizedBox(width: 10),

          // Right: duration + radio
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(CupertinoIcons.clock, size: 10, color: captionColor),
              const SizedBox(width: 3),
              Text(option.duration,
                  style: TextStyle(fontSize: 10, color: captionColor)),
            ]),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFCBD5E0)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
          ]),
        ]),
      ),
    );
  }
}
