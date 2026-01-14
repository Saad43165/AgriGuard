// lib/features/ResultScreen/presentation/components/results/image_preview_results.dart
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
    final hasImage = imagePath != null && File(imagePath).existsSync();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            ? Image.file(File(imagePath!), fit: BoxFit.cover)
            : Container(
          color: theme.colorScheme.surface.withOpacity(0.3),
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}