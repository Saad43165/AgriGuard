import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'image_preview.dart';

class ImageSection extends StatefulWidget {
  final XFile? imageFile;
  final Animation<double> scaleAnimation;
  final bool isLoading;
  final bool modelReady;
  final String? imageUrl;
  final dynamic timestamp;

  const ImageSection({
    super.key,
    required this.imageFile,
    required this.scaleAnimation,
    required this.isLoading,
    this.modelReady = false,
    this.imageUrl,
    this.timestamp,
  });

  @override
  State<ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<ImageSection>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  bool _isHovering = false;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  // AI Analysis suggestions - Updated for MobileNetV3
  final List<String> _aiSuggestions = [
    '🌿 12 plant species supported',
    '📸 Ensure good lighting for best results',
    '🔍 Focus on leaves and stems',
    '📏 Keep camera 6-12 inches away',
    '🎯 MobileNetV3Large AI ready',
  ];
  int _currentSuggestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSuggestionRotation();
  }

  void _initializeAnimations() {
    // Shimmer effect for loading
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  void _startSuggestionRotation() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && widget.imageFile == null) {
        setState(() {
          _currentSuggestionIndex = (_currentSuggestionIndex + 1) % _aiSuggestions.length;
        });
        _startSuggestionRotation();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }
    _lastTapTime = now;

    HapticFeedback.lightImpact();

    if (_tapCount >= 3 && widget.imageFile != null) {
      _showImageAnalysisPreview();
    }
  }

  void _showImageAnalysisPreview() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickAnalysisSheet(),
    );
  }

  Widget _buildQuickAnalysisSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Image Check',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.modelReady ? 'Ready for AI analysis' : 'Model not ready',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.modelReady
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCheckItem('AI Model', widget.modelReady, widget.modelReady ? 'Ready' : 'Not Ready'),
          _buildCheckItem('Image Quality', true, 'Good'),
          _buildCheckItem('File Size', true, 'Optimal'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.modelReady ? Icons.check_circle : Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.modelReady ? 'Ready to Analyze!' : 'Model Loading...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool isGood, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isGood ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isGood ? Icons.check_circle : Icons.info,
              color: isGood ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            status,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isGood ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMeasurements.defaultPadding,
      ),
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: widget.imageFile != null ? _showImageAnalysisPreview : null,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                AppMeasurements.getResponsiveBorderRadius(context),
              ),
              boxShadow: widget.imageFile != null
                  ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(_isHovering ? 0.3 : 0.1),
                  blurRadius: _isHovering ? 30 : 20,
                  offset: Offset(0, _isHovering ? 12 : 8),
                  spreadRadius: _isHovering ? 2 : 0,
                ),
              ]
                  : null,
            ),
            child: Stack(
              children: [
                // Main content
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppMeasurements.getResponsiveBorderRadius(context),
                  ),
                  child: widget.isLoading
                      ? _buildAdvancedLoadingState(context)
                      : widget.imageFile == null
                      ? _buildInteractiveEmptyState(context)
                      : _buildEnhancedImagePreview(context),
                ),

                // Floating hint for triple tap
                if (widget.imageFile != null && _tapCount == 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value > 0.7 ? 1.0 - (value - 0.7) * 3.33 : value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Triple tap for quick check',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedLoadingState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated shimmer effect
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shimmerAnimation.value * 200, 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.image_search,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Preparing image...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: 100),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Text(
                      '$value%',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.modelReady ? 'Ready to Scan' : 'Loading AI Model...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _aiSuggestions[_currentSuggestionIndex],
                key: ValueKey(_currentSuggestionIndex),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedImagePreview(BuildContext context) {
    return ImagePreview(
      imageFile: widget.imageFile,
      scaleAnimation: widget.scaleAnimation,
      imageUrl: widget.imageUrl,
      scanTimestamp: widget.timestamp,
      modelReady: widget.modelReady,
    );
  }
}