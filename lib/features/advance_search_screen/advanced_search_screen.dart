import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  bool _isCheckingApis = true; // show loading while checking API availability
  int _selectedAnalysisType = 0; // 0 = Cloud Vision (HF), 1 = Plant.id, 2 = Groq advice
  Map<String, dynamic>? _apiStatus;

  final AdvancedSearchService _searchService = AdvancedSearchService();

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
      'descKey': 'plantid_desc',
      'icon': Icons.local_florist_rounded,
      'duration': '3-5',
      'type': 'PlantId',
      'color': const Color(0xFF4CAF50),
    },
    {
      'titleKey': 'groq_ai',
      'descKey': 'groq_desc',
      'icon': Icons.auto_awesome_rounded,
      'duration': '2-4',
      'type': 'Advice',
      'color': const Color(0xFF3B82F6),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkApiAvailability();
  }

  Future<void> _checkApiAvailability() async {
    try {
      final status = await _searchService.testAllApis();
      if (mounted) setState(() { _apiStatus = status; _isCheckingApis = false; });
    } catch (_) {
      if (mounted) setState(() { _apiStatus = {'success': false}; _isCheckingApis = false; });
    }
  }

  bool _isOptionAvailable(int index) {
    final status = _apiStatus;
    if (status == null) return true; // don't block while loading

    if (index == 0) {
      final hf = status['huggingface'];
      return hf is Map ? (hf['available'] == true) : false;
    }
    if (index == 1) {
      final plantId = status['plantId'];
      return plantId is Map ? (plantId['available'] == true) : false;
    }
    if (index == 2) {
      final groq = status['groq'];
      return groq is Map ? (groq['available'] == true) : false;
    }
    return true;
  }

  String? _unavailableReason(int index) {
    final status = _apiStatus;
    if (status == null) return null;
    if (index == 0) return (status['huggingface'] as Map?)?['message']?.toString();
    if (index == 1) return (status['plantId'] as Map?)?['message']?.toString();
    if (index == 2) return (status['groq'] as Map?)?['message']?.toString();
    return null;
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
    final t = Provider.of<TranslationService>(context, listen: false);
    if (_isAnalyzing) return;
    if (!_isOptionAvailable(_selectedAnalysisType)) {
      _showError(_unavailableReason(_selectedAnalysisType) ??
          t.get('error_selected_method_unavailable'));
      return;
    }

    final imagePath = widget.originalScanData['imagePath'] as String?;
    if (imagePath == null) {
      _showError(t.get('error_file_not_found'));
      return;
    }

    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      _showError(t.get('error_file_not_found'));
      return;
    }

    final fileSize = await imageFile.length();
    if (fileSize > 5 * 1024 * 1024) {
      _showError(t.get('error_image_too_large_5mb'));
      return;
    }

    final selectedType = _selectedAnalysisType == 0
        ? 'HuggingFace'
        : _selectedAnalysisType == 1
            ? 'Plant.id'
            : 'Groq';

    HapticFeedback.mediumImpact();
    setState(() => _isAnalyzing = true);

    try {
      Map<String, dynamic> result;

      if (selectedType == 'HuggingFace') {
        result = await _searchService.analyzeWithHuggingFace(imageFile);
      } else if (selectedType == 'Plant.id') {
        result = await _searchService.analyzeWithPlantId(imageFile);
      } else {
        result = await _searchService.analyzePlant(imageFile);
      }

      if (!mounted) return;

      setState(() => _isAnalyzing = false);

      if (result['success'] == true) {
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
        _showError('$selectedType Error: $errorMessage');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showError('${t.get('error_unexpected')}: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    final t = Provider.of<TranslationService>(context, listen: false);
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
          label: t.get('dismiss'),
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
          color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F7FF),
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
                  child: Consumer<TranslationService>(
                    builder: (context, t, child) => _buildContent(t),
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
            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
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
      title: Consumer<TranslationService>(
        builder: (context, t, _) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            t.get('advanced_analysis'),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        // Language Toggle
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
          child: Consumer<TranslationService>(
            builder: (context, t, child) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => t.toggleLanguage(),
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
                            t.isUrdu ? 'EN' : 'اردو',
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

  Widget _buildContent(TranslationService t) {
    if (_isCheckingApis) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking available services...'),
          ],
        ),
      );
    }

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
                t.get('analysis_methods'),
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
            final isAvailable = _isOptionAvailable(index);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnalysisOptionCard(
                option: option,
                isSelected: isSelected,
                isAvailable: isAvailable,
                unavailableReason: _unavailableReason(index),
                onTap: () {
                  if (!_isAnalyzing) {
                    if (isAvailable) {
                      setState(() => _selectedAnalysisType = index);
                    } else {
                      _showError(_unavailableReason(index) ??
                          t.get('error_option_unavailable'));
                    }
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
            isAvailable: _isOptionAvailable(_selectedAnalysisType),
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