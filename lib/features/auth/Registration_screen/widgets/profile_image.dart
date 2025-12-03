// features/auth/Registration_screen/weather_screen/profile_image_widget.dart

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
    final padding = AppMeasurements.getResponsivePadding(context);

    return GestureDetector(
      onTap: isLoading ? null : onImagePressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildImageContent(context),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          if (!isLoading)
            Positioned(
              bottom: 0,
              right: 115,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (imageFile != null) {
      return Image.file(
        imageFile!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderContent(context);
        },
      );
    } else {
      return _buildPlaceholderContent(context);
    }
  }

  Widget _buildPlaceholderContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: 50,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      ),
    );
  }
}