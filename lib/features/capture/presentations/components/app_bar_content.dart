import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_measurements.dart';

class AppBarContent extends StatelessWidget {
  final XFile? imageFile;
  final VoidCallback onRetake;

  const AppBarContent({
    super.key,
    required this.imageFile,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 50,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            'Scan Leaf',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 24),
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
        ),
      ),
      pinned: true,
      actions: [
        if (imageFile != null)
          Padding(
            padding: const EdgeInsets.only(right: AppMeasurements.smallPadding),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  ],
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                  onTap: onRetake,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: AppMeasurements.getResponsiveIconSizeSmall(context),
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