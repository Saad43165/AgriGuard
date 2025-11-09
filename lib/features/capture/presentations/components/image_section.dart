import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'image_preview.dart';

class ImageSection extends StatelessWidget {
  final XFile? imageFile;
  final Animation<double> scaleAnimation;
  final bool isLoading;
  final String? imageUrl;
  final dynamic timestamp;

  const ImageSection({
    super.key,
    required this.imageFile,
    required this.scaleAnimation,
    required this.isLoading,
    this.imageUrl,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMeasurements.defaultPadding,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
          boxShadow: imageFile != null
              ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
          child: isLoading
              ? _buildLoadingState(context)
              : ImagePreview(
            imageFile: imageFile,
            scaleAnimation: scaleAnimation,
            imageUrl: imageUrl,
            scanTimestamp: timestamp,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
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
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading image...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}