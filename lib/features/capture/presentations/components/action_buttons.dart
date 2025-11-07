import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../core/widgets/glass_card.dart';
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Reduced padding
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly spread buttons
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4), // Small margin
                      child: ImageButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        isPrimary: true,
                        isEnabled: !isLoading,
                        onPressed: () => onPickImage(ImageSource.camera),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4), // Small margin
                      child: ImageButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        isPrimary: false,
                        isEnabled: !isLoading,
                        onPressed: () => onPickImage(ImageSource.gallery),
                      ),
                    ),
                  ),
                ],
              ),
              if (imageFile != null) const SizedBox(height: 12), // Reduced spacing
              if (imageFile != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 4), // Consistent margin
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                      onTap: isProcessing ? null : onProcess,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Reduced padding
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
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Analyzing...',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 15),
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
                            const SizedBox(width: 6),
                            Text(
                              'Analyze Leaf',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 15),
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