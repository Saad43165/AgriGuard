import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/services/translation_service.dart';
import 'source_card.dart';
import 'step_header.dart';
import 'photo_tips.dart';

class SourceSelectionScreen extends StatefulWidget {
  final bool isLoading;
  final String? selectedMethod;
  final VoidCallback onCameraSelect;
  final VoidCallback onGallerySelect;

  const SourceSelectionScreen({
    super.key,
    required this.isLoading,
    this.selectedMethod,
    required this.onCameraSelect,
    required this.onGallerySelect,
  });

  @override
  State<SourceSelectionScreen> createState() => _SourceSelectionScreenState();
}

class _SourceSelectionScreenState extends State<SourceSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final translation = TranslationService();

    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
          child: Column(
            children: [
              const SizedBox(height: 20),

              StepHeader(
                title: translation.get('source_title'),
                subtitle: translation.get('source_subtitle'),
                stepNumber: 2,
              ),

              const SizedBox(height: 24),

              // Camera Option
              SourceCard(
                source: ImageSource.camera,
                icon: Icons.camera_alt_rounded,
                titleKey: 'camera',
                descKey: 'camera_desc',
                tips: [
                  translation.get('tip_1'),
                  translation.get('tip_2'),
                  translation.get('tip_3'),
                ],
                gradient: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                isLoading: widget.isLoading,
                onTap: () {
                  widget.onCameraSelect();
                },
              ),

              const SizedBox(height: 16),

              // Gallery Option
              SourceCard(
                source: ImageSource.gallery,
                icon: Icons.photo_library_rounded,
                titleKey: 'gallery',
                descKey: 'gallery_desc',
                tips: [
                  translation.get('tip_1'),
                  translation.get('tip_2'),
                  translation.get('tip_3'),
                ],
                gradient: const [
                  Color(0xFF00C9FF),
                  Color(0xFF92FE9D),
                ],
                isLoading: widget.isLoading,
                onTap: () {
                  widget.onGallerySelect();
                },
              ),

              const SizedBox(height: 24),

              // Photo Tips
              const PhotoTips(),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}