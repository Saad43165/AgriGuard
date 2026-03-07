import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ImageSection extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final String? imageBase64;

  const ImageSection({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.imageBase64,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: ResultScreenConstants.imageHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResultScreenConstants.imageBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResultScreenConstants.imageBorderRadius),
        child: _buildImageWidget(theme),
      ),
    );
  }

  Widget _buildImageWidget(ThemeData theme) {
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64!);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        debugPrint('❌ Error decoding base64 image: $e');
      }
    }

    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildNoImagePlaceholder(theme),
      );
    }

    return _buildNoImagePlaceholder(theme);
  }

  Widget _buildNoImagePlaceholder(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withOpacity(0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(ResultScreenConstants.imageBorderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_rounded,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No image available',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}