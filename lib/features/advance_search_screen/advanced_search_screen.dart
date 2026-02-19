import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/floating_orb.dart';
import 'components/analysis_info_note.dart';
import 'components/analysis_option_card.dart';
import 'components/analysis_start_button.dart';
import 'components/header_card.dart';
import 'components/image_preview_card.dart';
import '../advance_result_screen/advanced_result_screen.dart';
import 'service/advanced_search_service.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final Map<String, dynamic> originalScanData;

  const AdvancedSearchScreen({
    super.key,
    required this.originalScanData,
  });

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isAnalyzing = false;
  int _selectedAnalysisType = 0; // 0 = Cloud, 1 = Plant.id

  final AdvancedSearchService _searchService = AdvancedSearchService();
  final TranslationService _translation = TranslationService();

  // Using translation keys instead of hardcoded text
  List<Map<String, dynamic>> get _analysisOptions => [
    {
      'titleKey': 'cloud_ai',
      'descKey': 'cloud_ai_desc',
      'icon': Icons.psychology_rounded,
      'duration': '2-5',
      'type': 'Cloud',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'titleKey': 'plantid',
      'descKey': 'plantiddesc',
      'icon': Icons.local_florist_rounded,
      'duration': '3-5',
      'type': 'PlantId',
      'color': const Color(0xFF4CAF50),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _translation.loadLanguage();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _startAdvancedAnalysis() async {
    if (_isAnalyzing) return;

    final imagePath = widget.originalScanData['imagePath'] as String?;
    if (imagePath == null) {
      _showError(_translation.get('error_file_not_found'));
      return;
    }

    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      _showError(_translation.get('error_file_not_found'));
      return;
    }

    final fileSize = await imageFile.length();
    if (fileSize > 5 * 1024 * 1024) {
      _showError('Image is too large (max 5MB)');
      return;
    }

    final selectedType = _selectedAnalysisType == 0 ? 'Gemini' : 'Plant.id';

    HapticFeedback.mediumImpact();
    setState(() => _isAnalyzing = true);

    try {
      Map<String, dynamic> result;

      if (selectedType == 'Gemini') {
        debugPrint('🎯 Selected: Cloud AI Analysis');
        result = await _searchService.analyzePlant(imageFile);
      } else {
        debugPrint('🎯 Selected: Plant.id Professional');
        result = await _searchService.analyzeWithPlantId(imageFile);
      }

      if (!mounted) return;

      setState(() => _isAnalyzing = false);

      if (result['success'] == true) {
        debugPrint('✅ Analysis successful with ${result['source']}');
        HapticFeedback.lightImpact();

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdvancedResultsScreen(
              analysisResult: result,
              originalScanData: widget.originalScanData,
            ),
          ),
        );
      } else {
        final errorMessage =
            result['message'] ?? result['error'] ?? 'Analysis failed';
        debugPrint('❌ Analysis failed: $errorMessage');
        _showError('$selectedType Error: $errorMessage');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        debugPrint('❌ Unexpected error: $e');
        _showError('Unexpected error: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: _translation.get('dismiss'),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: !_isAnalyzing,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context, isDark),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [
                Color(0xFF0F0F23),
                Color(0xFF16213E),
                Color(0xFF1A1A2E),
              ]
                  : [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.9),
                theme.colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background orbs
              ...List.generate(
                8,
                    (i) => FloatingOrb(
                  index: i,
                  maxWidth: size.width,
                  fadeController: _fadeController,
                  scaleAnimation: _scaleAnimation,
                ),
              ),

              // Main content - wrapped with AnimatedBuilder
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: AnimatedBuilder(
                    animation: _translation,
                    builder: (context, child) => _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.25)
                  : Colors.black.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isAnalyzing
                  ? null
                  : () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      title: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ).createShader(bounds),
        child: Text(
          _translation.get('advanced_analysis'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        // Language Toggle
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
          child: AnimatedBuilder(
            animation: _translation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.25)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _translation.toggleLanguage(),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language_rounded,
                            size: 18,
                            color: isDark
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _translation.isUrdu ? 'EN' : 'اردو',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          HeaderCard(padding: 24),

          const SizedBox(height: 20),

          // Image Preview
          ImagePreviewCard(
            imagePath: widget.originalScanData['imagePath'] as String?,
          ),

          const SizedBox(height: 28),

          // Section Title
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _translation.get('analysis_methods'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Analysis Options
          ...List.generate(_analysisOptions.length, (index) {
            final option = _analysisOptions[index];
            final isSelected = _selectedAnalysisType == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnalysisOptionCard(
                option: option,
                isSelected: isSelected,
                isAvailable: true,
                onTap: () {
                  if (!_isAnalyzing) {
                    setState(() => _selectedAnalysisType = index);
                  }
                },
              ),
            );
          }),

          const SizedBox(height: 20),

          // Start Button
          AnalysisStartButton(
            isAnalyzing: _isAnalyzing,
            selectedOption: _analysisOptions[_selectedAnalysisType],
            isAvailable: true,
            onPressed: _startAdvancedAnalysis,
          ),

          const SizedBox(height: 16),

          // Info Note
          const AnalysisInfoNote(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}