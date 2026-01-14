import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../core/widgets/floating_orb.dart';
import 'components/analysis_info_note.dart';
import 'components/analysis_option_card.dart';
import 'components/analysis_overlay.dart';
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
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isAnalyzing = false;
  int _selectedAnalysisType = 0; // 0 = Gemini, 1 = Plant.id

  final AdvancedSearchService _searchService = AdvancedSearchService();

  final List<Map<String, dynamic>> _analysisOptions = [
    {
      'title': 'Gemini AI Analysis',
      'description': 'Advanced AI-powered plant disease detection using Google Gemini',
      'icon': Icons.psychology,
      'duration': '2-5 seconds',
      'type': 'Gemini',
      'features': [
        'Advanced disease detection',
        'Detailed analysis reports',
        'High accuracy on field images',
        'Multiple disease classification',
        'Cause identification included'
      ],
      'color': Color(0xFF8B5CF6),
    },
    {
      'title': 'Plant.id Professional',
      'description': 'Specialized plant & disease identification with AI',
      'icon': Icons.local_florist,
      'duration': '3-5 seconds',
      'type': 'PlantId',
      'features': [
        'Advanced plant identification',
        'Disease detection & diagnosis',
        'Treatment recommendations',
        'Severity assessment'
      ],
      'color': Color(0xFF4CAF50),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startAdvancedAnalysis() async {
    if (_isAnalyzing) return;

    final imagePath = widget.originalScanData['imagePath'] as String?;
    if (imagePath == null) {
      _showError('No image data found');
      return;
    }

    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      _showError('Image file not found');
      return;
    }

    // Check file size
    final fileSize = await imageFile.length();
    if (fileSize > 5 * 1024 * 1024) { // 5MB limit
      _showError('Image is too large (max 5MB)');
      return;
    }

    final selectedType = _selectedAnalysisType == 0 ? 'Gemini' : 'Plant.id';

    HapticFeedback.mediumImpact();
    setState(() => _isAnalyzing = true);

    try {
      Map<String, dynamic> result;

      if (selectedType == 'Gemini') {
        debugPrint('🎯 Selected: Gemini AI Analysis');
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
        final errorMessage = result['message'] ?? result['error'] ?? 'Analysis failed';
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Dismiss',
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
    final size = MediaQuery.of(context).size;
    final padding = AppMeasurements.getResponsivePadding(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 8),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button on LEFT SIDE
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                      ],
                    ),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context) * 0.5),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: AppMeasurements.getResponsiveIconSizeMedium(context),
                        ),
                      ),
                    ),
                  ),
                ),

                // Title in Center with Gradient
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Advanced Analysis',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 26),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Empty Spacer on RIGHT SIDE
                Container(width: 50),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? const [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF0F172A)]
                : const [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
          ),
        ),
        child: Stack(
          children: [
            // Animated orbs
            ...List.generate(
              4,
                  (i) => FloatingOrb(
                index: i,
                maxWidth: size.width,
                fadeController: _fadeController,
                scaleAnimation: _scaleAnimation,
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeController,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padding, padding * 0.5, padding, 0),
                        child: HeaderCard(padding: padding),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: ImagePreviewCard(
                          imagePath: widget.originalScanData['imagePath'] as String?,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            padding,
                            padding * 1.5,
                            padding,
                            padding * 0.5
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Analysis Methods',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final option = _analysisOptions[index];
                            final isSelected = _selectedAnalysisType == index;

                            return Padding(
                              padding: EdgeInsets.only(bottom: padding),
                              child: AnalysisOptionCard(
                                option: option,
                                isSelected: isSelected,
                                isAvailable: true,
                                pulseAnimation: isSelected ? _pulseAnimation : null,
                                onTap: () {
                                  if (!_isAnalyzing) {
                                    setState(() => _selectedAnalysisType = index);
                                  }
                                },
                              ),
                            );
                          },
                          childCount: _analysisOptions.length,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padding, padding, padding, padding),
                        child: AnalysisStartButton(
                          isAnalyzing: _isAnalyzing,
                          selectedOption: _analysisOptions[_selectedAnalysisType],
                          isAvailable: true,
                          onPressed: _startAdvancedAnalysis,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padding, 0, padding, padding * 2),
                        child: const AnalysisInfoNote(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isAnalyzing)
              AnalysisOverlay(
                theme: theme,
                selectedOption: _analysisOptions[_selectedAnalysisType],
              ),
          ],
        ),
      ),
    );
  }
}