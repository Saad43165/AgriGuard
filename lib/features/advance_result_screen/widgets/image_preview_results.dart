// lib/features/ResultScreen/presentation/widgets/results/image_preview_results.dart
import 'dart:convert'; // ADD THIS
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_measurements.dart';

class ImagePreviewResults extends StatelessWidget {
  final Map<String, dynamic> originalScanData;
  final ThemeData theme;

  const ImagePreviewResults({
    super.key,
    required this.originalScanData,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = originalScanData['imagePath'] as String?;
    final imageBase64 = originalScanData['imageBase64'] as String?;
    final imageUrl = originalScanData['imageUrl'] as String?;

    // Check all possible image sources
    final hasImage = _hasAnyImage(imagePath, imageBase64, imageUrl);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        child: hasImage
            ? _buildImage(imagePath, imageBase64, imageUrl, context)
            : _buildNoImagePlaceholder(),
      ),
    );
  }

  bool _hasAnyImage(String? imagePath, String? imageBase64, String? imageUrl) {
    // Check base64
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      return true;
    }

    // Check local file
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        return file.existsSync();
      } catch (e) {
        return false;
      }
    }

    // Check URL
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return true;
    }

    return false;
  }

  Widget _buildImage(String? imagePath, String? imageBase64, String? imageUrl, BuildContext context) {
    Widget imageWidget;

    // Priority 1: Base64 image
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
        );
        debugPrint('✅ ImagePreviewResults: Displaying base64 image');
      } catch (e) {
        debugPrint('❌ ImagePreviewResults: Error decoding base64: $e');
        imageWidget = _buildNoImagePlaceholder();
      }
    }
    // Priority 2: Local file
    else if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: BoxFit.cover,
          );
          debugPrint('✅ ImagePreviewResults: Displaying file image: $imagePath');
        } else {
          debugPrint('❌ ImagePreviewResults: File does not exist: $imagePath');
          imageWidget = _buildNoImagePlaceholder();
        }
      } catch (e) {
        debugPrint('❌ ImagePreviewResults: Error loading file: $e');
        imageWidget = _buildNoImagePlaceholder();
      }
    }
    // Priority 3: Network URL
    else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ ImagePreviewResults: Network image error: $error');
          return _buildNoImagePlaceholder();
        },
      );
      debugPrint('✅ ImagePreviewResults: Displaying network image');
    }
    // No image available
    else {
      debugPrint('❌ ImagePreviewResults: No image data available');
      imageWidget = _buildNoImagePlaceholder();
    }

    return imageWidget;
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No image available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}