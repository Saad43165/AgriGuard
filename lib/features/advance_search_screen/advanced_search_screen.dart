import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import '../advance_result_screen/advanced_result_screen.dart';
import 'service/advanced_search_service.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final Map<String, dynamic> originalScanData;
  const AdvancedSearchScreen({super.key, required this.originalScanData});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  bool _isAnalyzing = false;
  bool _isCheckingApis = true;
  int _selectedIndex = 2; // default Groq
  Map<String, dynamic>? _apiStatus;
  final AdvancedSearchService _searchService = AdvancedSearchService();

  static const _options = [
    _Option('Disease Scanner', 'Identifies plant diseases from photo', CupertinoIcons.leaf_arrow_circlepath, 'HuggingFace', '3–6s'),
    _Option('Plant Expert', 'Deep plant & disease identification', CupertinoIcons.tree, 'Plant.id', '3–5s'),
    _Option('AI Advisor', 'Get expert farming advice & treatment', CupertinoIcons.chat_bubble_text, 'Groq', '2–4s'),
  ];

  List<_Option> _localizedOptions(TranslationService t) => t.isUrdu ? [
    _Option('ڈیزیز اسکینر', 'تصویر سے پودوں کی بیماریاں شناخت کرتا ہے', CupertinoIcons.leaf_arrow_circlepath, 'HuggingFace', '3–6s'),
    _Option('پلانٹ ایکسپرٹ', 'گہری پودوں اور بیماریوں کی شناخت', CupertinoIcons.tree, 'Plant.id', '3–5s'),
    _Option('AI مشیر', 'ماہرانہ زرعی مشورہ اور علاج', CupertinoIcons.chat_bubble_text, 'Groq', '2–4s'),
  ] : _options;

  @override
  void initState() {
    super.initState();
    _checkApis();
  }

  Future<void> _checkApis() async {
    try {
      final s = await _searchService.testAllApis();
      if (mounted) {
        setState(() {
          _apiStatus = s;
          _isCheckingApis = false;
          // If currently selected option is offline, fall back to first available
          if (!_available(_selectedIndex)) {
            for (int i = 0; i < _options.length; i++) {
              if (_available(i)) { _selectedIndex = i; break; }
            }
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() { _apiStatus = {}; _isCheckingApis = false; });
    }
  }

  bool _available(int i) {
    // Index 0 (Disease Scanner / PlantNet) is always available — no key needed
    if (i == 0) return true;
    if (_apiStatus == null) return true; // still checking — optimistic
    final keys = ['huggingface', 'plantId', 'groq'];
    final v = _apiStatus![keys[i]];
    return v is Map ? (v['available'] == true) : false;
  }

  Future<void> _start() async {
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
      if (tag == 'HuggingFace') {
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
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => AdvancedResultsScreen(
            analysisResult: result,
            originalScanData: widget.originalScanData,
          ),
        ));
      } else if (result['isNonLeaf'] == true) {
        // Non-leaf image — show friendly message and pop back
        _err(t.isUrdu
            ? 'یہ پودے کے پتے کی تصویر نہیں ہے۔ براہ کرم پتے کی واضح تصویر لیں۔'
            : 'This doesn\'t appear to be a plant leaf. Please take a clear photo of a leaf.');
      } else {
        _err(result['message'] ?? result['error'] ?? (t.isUrdu ? 'تجزیہ ناکام ہوا۔' : 'Analysis failed.'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _err(t.isUrdu ? 'خرابی: $e' : 'Error: $e');
      }
    }
  }

  // cached translation reference for use in _start()
  TranslationService get t => TranslationService();

  void _err(String msg) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(CupertinoIcons.exclamationmark_circle, color: Colors.white, size: 16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context, listen: false);
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final imagePath = widget.originalScanData['imagePath'] as String?;

    return PopScope(
      canPop: !_isAnalyzing,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Column(children: [
            // ── Image top 45% ──────────────────────────────────────────
            Expanded(
              flex: 45,
              child: Stack(fit: StackFit.expand, children: [
                if (imagePath != null && File(imagePath).existsSync())
                  Image.file(File(imagePath), fit: BoxFit.cover)
                else
                  Container(color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Center(child: Icon(CupertinoIcons.photo, size: 64, color: AppColors.primary))),
                // Bottom fade
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(height: 80,
                    decoration: BoxDecoration(gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [isDark ? AppColors.darkCard : Colors.white, Colors.transparent],
                    )))),
                // Back
                Positioned(top: MediaQuery.of(context).padding.top + 12, left: 16,
                  child: GestureDetector(
                    onTap: _isAnalyzing ? null : () => Navigator.pop(context),
                    child: Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                      child: const Icon(CupertinoIcons.back, color: Colors.white, size: 18)))),
                // Lang toggle
                Positioned(top: MediaQuery.of(context).padding.top + 12, right: 16,
                  child: Consumer<TranslationService>(builder: (_, t, __) =>
                    GestureDetector(onTap: () => t.toggleLanguage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20)),
                        child: Text(t.isUrdu ? 'EN' : 'اردو',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))))),
              ]),
            ),

            // ── Bottom sheet 55% ───────────────────────────────────────
            Expanded(
              flex: 55,
              child: Container(
                color: isDark ? AppColors.darkCard : Colors.white,
                padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.isUrdu ? 'ایڈوانسڈ AI تجزیہ' : 'Advanced AI Analysis',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: textColor, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(t.isUrdu ? 'گہری پودوں کی تشخیص کے لیے AI طریقہ منتخب کریں' : 'Choose an AI method for deeper plant diagnosis',
                    style: TextStyle(fontSize: 13, color: captionColor)),
                  const SizedBox(height: 16),

                  if (_isCheckingApis)
                    Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                      const SizedBox(height: 12),
                      Text(t.isUrdu ? 'سروسز چیک ہو رہی ہیں…' : 'Checking services…', style: TextStyle(fontSize: 13, color: captionColor)),
                    ])))
                  else ...[
                    Expanded(child: Column(children: List.generate(_options.length, (i) =>
                      Padding(padding: const EdgeInsets.only(bottom: 10),
                        child: _OptionCard(
                          option: _localizedOptions(t)[i],
                          isSelected: _selectedIndex == i,
                          isAvailable: _available(i),
                          isDark: isDark,
                          onTap: _available(i) && !_isAnalyzing ? () => setState(() => _selectedIndex = i) : null,
                        ))))),

                    SizedBox(width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isAnalyzing ? null : _start,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        child: _isAnalyzing
                          ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                              const SizedBox(width: 10), Text(t.isUrdu ? 'تجزیہ ہو رہا ہے…' : 'Analyzing…')])
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(CupertinoIcons.sparkles, size: 18),
                              const SizedBox(width: 8),
                              Text(t.isUrdu
                                  ? '${_options[_selectedIndex].title} سے تجزیہ کریں'
                                  : 'Analyze with ${_options[_selectedIndex].title}')]),
                      )),
                  ],
                ]),
              ),
            ),
          ]),

          // Analyzing overlay
          if (_isAnalyzing)
            Container(color: Colors.black.withValues(alpha: 0.5),
              child: Center(child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text('${t.isUrdu ? '' : 'Analyzing with '}${_localizedOptions(t)[_selectedIndex].title}${t.isUrdu ? ' سے تجزیہ ہو رہا ہے…' : '…'}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(t.isUrdu ? 'اس میں چند سیکنڈ لگ سکتے ہیں' : 'This may take a few seconds',
                    style: TextStyle(fontSize: 12, color: captionColor)),
                ]),
              ))),
        ]),
      ),
    );
  }
}

class _Option {
  final String title, subtitle, tag, duration;
  final IconData icon;
  const _Option(this.title, this.subtitle, this.icon, this.tag, this.duration);
}

class _OptionCard extends StatelessWidget {
  final _Option option;
  final bool isSelected, isAvailable, isDark;
  final VoidCallback? onTap;
  const _OptionCard({required this.option, required this.isSelected,
    required this.isAvailable, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Row(children: [
          // Icon box — always white/dark, no color tint
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Icon(option.icon,
              color: isSelected ? AppColors.primary : captionColor,
              size: 20),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(option.title,
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: isAvailable ? textColor : captionColor,
                )),
              if (!isAvailable) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text('Offline',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: AppColors.error))),
              ],
            ]),
            const SizedBox(height: 3),
            Text(option.subtitle,
              style: TextStyle(fontSize: 12, color: captionColor, height: 1.3)),
          ])),

          const SizedBox(width: 12),

          // Right side: duration + radio
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(CupertinoIcons.clock, size: 10, color: captionColor),
              const SizedBox(width: 3),
              Text(option.duration,
                style: TextStyle(fontSize: 10, color: captionColor)),
            ]),
            const SizedBox(height: 8),
            // Radio circle
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E0)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                  : null,
            ),
          ]),
        ]),
      ),
    );
  }
}




