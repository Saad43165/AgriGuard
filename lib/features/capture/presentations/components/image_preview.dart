import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_measurements.dart';

class ImagePreview extends StatelessWidget {
  final XFile? imageFile;
  final Animation<double> scaleAnimation;
  final String? imageUrl;
  final DateTime? scanTimestamp;

  const ImagePreview({
    super.key,
    required this.imageFile,
    required this.scaleAnimation,
    this.imageUrl,
    this.scanTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    if (imageFile == null) {
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
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'No image selected',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
            ),
          ),

          const SizedBox(height: 8),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Capture or select a leaf image to begin analysis',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return ScaleTransition(
      scale: scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
          child: Stack(
            children: [
              // Image with border
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1,
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
                    child: Image.file(
                      File(imageFile!.path),
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

              // Enhanced status badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ready to Scan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Zoom hint overlay (bottom)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
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
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
            Theme.of(context).colorScheme.errorContainer.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Failed to load image',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please try selecting another image',
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