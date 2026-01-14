import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_measurements.dart';
import 'source_card.dart';
import 'step_header.dart';
import 'photo_tips.dart';

class SourceSelectionScreen extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCameraSelect;
  final VoidCallback onGallerySelect;

  const SourceSelectionScreen({
    super.key,
    required this.isLoading,
    required this.onCameraSelect,
    required this.onGallerySelect, String? selectedMethod,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Header
          StepHeader(
            title: 'Select Image Source',
            subtitle: 'Choose where to get your plant photo',
            stepNumber: 2,
          ),

          const SizedBox(height: 40),

          // Camera Option (no pulse animation)
          SourceCard(
            source: ImageSource.camera,
            icon: Icons.camera_alt_rounded,
            title: 'Take New Photo',
            description: 'Capture a fresh, clear photo of your plant leaf',
            tips: [
              'Use good natural lighting',
              'Focus on affected leaves',
              'Include whole leaf if possible',
            ],
            gradient: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
            ],
            isLoading: isLoading,
            onTap: onCameraSelect,
          ),

          const SizedBox(height: 24),

          // Gallery Option
          SourceCard(
            source: ImageSource.gallery,
            icon: Icons.photo_library_rounded,
            title: 'Choose from Gallery',
            description: 'Select an existing photo from your device',
            tips: [
              'Choose clear images',
              'Avoid blurry photos',
              'Single leaf works best',
            ],
            gradient: [
              const Color(0xFF00C9FF),
              const Color(0xFF92FE9D),
            ],
            isLoading: isLoading,
            onTap: onGallerySelect,
          ),

          const SizedBox(height: 32),

          // Photo Tips
          const PhotoTips(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}