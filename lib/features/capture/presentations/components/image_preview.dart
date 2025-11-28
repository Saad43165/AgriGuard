import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_measurements.dart';

class ImagePreview extends StatefulWidget {
  final XFile? imageFile;
  final Animation<double> scaleAnimation;
  final String? imageUrl;
  final DateTime? scanTimestamp;

  const ImagePreview({
    super.key,
    required this.imageFile,
    required this.scaleAnimation,
    this.imageUrl,
    this.scanTimestamp, required bool modelReady,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  bool _isAnalyzing = false;
  double _currentScale = 1.0;
  Offset _focusPoint = Offset.zero;
  bool _showAIOverlay = false;

  @override
  void initState() {
    super.initState();

    // AI scan line effect
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  void _triggerAIScanAnimation() {
    setState(() => _isAnalyzing = true);
    _scanLineController.forward(from: 0.0).then((_) {
      setState(() => _isAnalyzing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageFile == null) {
      return _buildEmptyState(context);
    }

    return _buildImagePreview(context);
  }

  Widget _buildEmptyState(BuildContext context) {
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
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple icon container
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
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 50,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Ready to Scan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'AI-powered leaf analysis',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Action indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap below to begin',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return ScaleTransition(
      scale: widget.scaleAnimation,
      child: GestureDetector(
        onDoubleTap: () {
          setState(() => _showAIOverlay = !_showAIOverlay);
          _triggerAIScanAnimation();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context),
            ),
            child: Stack(
              children: [
                // Main image with advanced viewer
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppMeasurements.getResponsiveBorderRadius(context),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppMeasurements.getResponsiveBorderRadius(context),
                    ),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      onInteractionUpdate: (details) {
                        setState(() {
                          _currentScale = details.scale;
                          _focusPoint = details.focalPoint;
                        });
                      },
                      child: Image.file(
                        File(widget.imageFile!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 300,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildErrorState(context);
                        },
                      ),
                    ),
                  ),
                ),

                // AI Scan Line Animation
                if (_isAnalyzing)
                  AnimatedBuilder(
                    animation: _scanLineController,
                    builder: (context, child) {
                      return Positioned(
                        top: 300 * _scanLineController.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Theme.of(context).colorScheme.primary,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary,
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // AI Analysis Overlay
                if (_showAIOverlay)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: AIAnalysisOverlayPainter(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                // Status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAnalyzing ? 'Analyzing' : 'Ready',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(_currentScale * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Zoom controls overlay
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.zoom_in_rounded,
                            size: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pinch to zoom',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 16,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.touch_app_rounded,
                            size: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Double tap for AI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
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
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
            Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Processing Failed',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Image could not be processed. Please select another image.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 13),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Simplified AI Analysis Overlay Painter
class AIAnalysisOverlayPainter extends CustomPainter {
  final Color color;

  AIAnalysisOverlayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw corner markers
    final cornerSize = 25.0;
    final corners = [
      Offset(15, 15),
      Offset(size.width - 15, 15),
      Offset(15, size.height - 15),
      Offset(size.width - 15, size.height - 15),
    ];

    for (final corner in corners) {
      canvas.drawLine(corner, corner + Offset(cornerSize, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, cornerSize), paint);
    }
  }

  @override
  bool shouldRepaint(AIAnalysisOverlayPainter oldDelegate) => false;
}