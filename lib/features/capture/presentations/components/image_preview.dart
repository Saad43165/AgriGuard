import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_measurements.dart';

class ImagePreview extends StatelessWidget {
  final XFile? imageFile;
  final Animation<double> scaleAnimation;

  const ImagePreview({
    super.key,
    required this.imageFile,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (imageFile == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppMeasurements.defaultPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.9),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                  ],
                ),
              ),
              child: Icon(
                Icons.eco_rounded,
                size: AppMeasurements.getResponsiveIconSizeLarge(context),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppMeasurements.defaultPadding),
            Text(
              'No leaf image selected',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
              ),
            ),
            const SizedBox(height: AppMeasurements.smallPadding),
            Text(
              'Capture a photo with your camera\nSelect from your gallery to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return ScaleTransition(
      scale: scaleAnimation,
      child: InteractiveViewer(
        panEnabled: true,
        minScale: 0.5,
        maxScale: 3.0,
        child: Stack(
          children: [
            Image.file(
              File(imageFile!.path),
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        size: AppMeasurements.getResponsiveIconSizeLarge(context),
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: AppMeasurements.smallPadding),
                      Text(
                        'Failed to load image',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.error,
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              bottom: AppMeasurements.smallPadding,
              left: AppMeasurements.smallPadding,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: AppMeasurements.getResponsiveIconSizeSmall(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Image ready',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}