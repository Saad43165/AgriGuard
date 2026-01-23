import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_measurements.dart';

class SourceCard extends StatelessWidget {
  final ImageSource source;
  final IconData icon;
  final String title;
  final String description;
  final List<String> tips;
  final List<Color> gradient;
  final bool isLoading;
  final VoidCallback? onTap;

  const SourceCard({
    super.key,
    required this.source,
    required this.icon,
    required this.title,
    required this.description,
    required this.tips,
    required this.gradient,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: MouseRegion(
        cursor: isLoading ? SystemMouseCursors.wait : SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradient[0].withOpacity(0.15),
                gradient[1].withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
            ),
            border: Border.all(
              color: gradient[0].withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildTipsSection(context),
              const SizedBox(height: 16),
              _buildActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14), // Reduced from 20
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(14), // Reduced from 16
          ),
          child: Icon(icon, color: Colors.white, size: 28), // Reduced from 36
        ),
        const SizedBox(width: 14), // Reduced from 20

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith( // Changed to bodySmall
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: gradient[0],
          size: 20, // Reduced from 24
        ),
      ],
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10), // Reduced from 12
      decoration: BoxDecoration(
        color: gradient[0].withOpacity(0.1),
        borderRadius: BorderRadius.circular(10), // Reduced from 12
        border: Border.all(color: gradient[0].withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, size: 16, color: gradient[0]), // Reduced from 18
              const SizedBox(width: 6), // Reduced from 8
              Text(
                'Tips for Best Results',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: gradient[0],
                  fontSize: 12, // Added font size
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // Reduced from 8
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3), // Reduced from 4
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 5, color: Colors.grey), // Reduced from 6
                const SizedBox(width: 6), // Reduced from 8
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 11, // Reduced from 13
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(10), // Reduced from 12
      ),
      child: TextButton(
        onPressed: isLoading ? null : onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14), // Match MethodCard
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              source == ImageSource.camera
                  ? Icons.camera_alt
                  : Icons.photo_library,
              color: Colors.white,
              size: 18, // Added size
            ),
            const SizedBox(width: 8), // Reduced from 12
            Text(
              isLoading ? 'Loading...' : 'Select This Option',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14, // Reduced from 16
              ),
            ),
          ],
        ),
      ),
    );
  }
}