import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';

class ImagePreviewCard extends StatelessWidget {
  final String? imagePath;

  const ImagePreviewCard({super.key, this.imagePath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppMeasurements.getResponsivePadding(context);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: imagePath != null && File(imagePath!).existsSync()
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.image, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Your Plant Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
            : Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.image_not_supported,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}