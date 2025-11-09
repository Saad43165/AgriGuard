import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_measurements.dart';

class AppBarContent extends StatelessWidget {
  final XFile? imageFile;
  final VoidCallback? onRetake;

  const AppBarContent({
    super.key,
    required this.imageFile,
    this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 80, // Reduced from 120
      collapsedHeight: 60, // Reduced from 70
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: AppMeasurements.getResponsivePadding(context),
          bottom: 8, // Reduced from 16
          right: imageFile != null ? 60 : 16, // Reduced padding
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Title with Gradient - More compact
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ).createShader(bounds),
              child: Text(
                'Scan Leaf',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20), // Smaller
                  letterSpacing: 0.3,
                ),
              ),
            ),

            // Subtitle - Only show when needed
            if (imageFile == null) // Only show subtitle when no image
              const SizedBox(height: 2), // Smaller gap
            if (imageFile == null)
              Text(
                'Capture or select an image',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 10), // Smaller
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.95),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppMeasurements.getResponsivePadding(context),
                vertical: 8, // Reduced vertical padding
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator - more compact
                  if (imageFile != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Smaller
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16), // Smaller radius
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, // Smaller dot
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 3, // Smaller shadow
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Image Selected',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 10), // Smaller
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      pinned: true,
      actions: [
        // More compact retake button
        if (imageFile != null && onRetake != null)
          Padding(
            padding: EdgeInsets.only(
              right: AppMeasurements.smallPadding,
              top: 4, // Reduced top padding
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  AppMeasurements.getResponsiveBorderRadius(context),
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1.2, // Slightly thinner border
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    blurRadius: 4, // Smaller shadow
                    offset: const Offset(0, 1), // Smaller offset
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    AppMeasurements.getResponsiveBorderRadius(context),
                  ),
                  onTap: onRetake,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Smaller padding
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: AppMeasurements.getResponsiveIconSizeSmall(context) * 0.9, // Smaller icon
                        ),
                        const SizedBox(width: 4), // Smaller gap
                        Text(
                          'Retake',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 11), // Smaller
                          ),
                        ),
                      ],
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