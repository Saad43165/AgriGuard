import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../Profile/presentation/Components/glass_card.dart';
import 'image_preview.dart';

class ImageSection extends StatelessWidget {
  final XFile? imageFile;
  final Animation<double> scaleAnimation;
  final bool isLoading;

  const ImageSection({
    super.key,
    required this.imageFile,
    required this.scaleAnimation,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppMeasurements.defaultPadding),
      child: GlassCard(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
          child: isLoading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : ImagePreview(
            imageFile: imageFile,
            scaleAnimation: scaleAnimation,
          ),
        ),
      ),
    );
  }
}