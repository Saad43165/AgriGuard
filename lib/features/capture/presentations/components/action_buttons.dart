import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../Profile/presentation/Components/glass_card.dart';
import 'image_Buttons.dart';


class ActionButtons extends StatelessWidget {
  final bool isLoading;
  final bool isProcessing;
  final XFile? imageFile;
  final Function(ImageSource) onPickImage;
  final VoidCallback onProcess;

  const ActionButtons({
    super.key,
    required this.isLoading,
    required this.isProcessing,
    required this.imageFile,
    required this.onPickImage,
    required this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ImageButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      isPrimary: true,
                      isEnabled: !isLoading,
                      onPressed: () => onPickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: AppMeasurements.smallPadding),
                  Expanded(
                    child: ImageButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      isPrimary: false,
                      isEnabled: !isLoading,
                      onPressed: () => onPickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              if (imageFile != null) const SizedBox(height: AppMeasurements.defaultPadding),
              if (imageFile != null)
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                      onTap: isProcessing ? null : onProcess,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: isProcessing
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Analyzing...',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_fix_high_rounded,
                              size: AppMeasurements.getResponsiveIconSizeSmall(context),
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Analyze Leaf',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}