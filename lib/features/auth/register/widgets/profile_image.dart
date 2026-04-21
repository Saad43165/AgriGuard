import 'dart:io';
import 'package:flutter/material.dart';
import 'package:agriguard_fyp/core/constants/app_measurements.dart';

class ProfileImageWidget extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onImagePressed;
  final bool isLoading;

  const ProfileImageWidget({
    super.key,
    required this.imageFile,
    required this.onImagePressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = AppMeasurements.getResponsiveSize(context, baseSize: 120);

    return GestureDetector(
      onTap: isLoading ? null : onImagePressed,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main profile image container
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildImageContent(theme, size),
              ),
            ),

            // Camera edit button - ALWAYS positioned at bottom-right of the circle
            Positioned(
              right: -4, // Move it slightly outside
              bottom: -4, // Move it slightly outside
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

            // Loading overlay
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(ThemeData theme, double size) {
    if (imageFile != null && imageFile!.existsSync()) {
      return Image.file(
        imageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(theme, size);
        },
      );
    } else {
      return _buildPlaceholder(theme, size);
    }
  }

  Widget _buildPlaceholder(ThemeData theme, double size) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_rounded,
              size: size * 0.35,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}