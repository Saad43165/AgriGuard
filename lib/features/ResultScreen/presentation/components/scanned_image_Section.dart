import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../Profile/presentation/Components/glass_card.dart';
import 'section_header.dart';

class ScannedImageSection extends StatelessWidget {
  final String imageUrl;

  const ScannedImageSection({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Scanned Image',
          icon: Icons.photo_camera_rounded,
        ),
        const SizedBox(height: AppMeasurements.smallPadding),
        GlassCard(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
            child: Image.file(
              File(imageUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                child: Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: AppMeasurements.getResponsiveIconSizeLarge(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}