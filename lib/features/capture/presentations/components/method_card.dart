import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';

class MethodCard extends StatelessWidget {
  final String method;
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
  final List<Color> gradient;
  final bool isReady;
  final String? loadingText;
  final VoidCallback? onSelect;

  const MethodCard({
    super.key,
    required this.method,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.gradient,
    required this.isReady,
    this.loadingText,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isReady ? onSelect : null,
      child: MouseRegion(
        cursor: isReady ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isReady
                  ? [gradient[0].withOpacity(0.15), gradient[1].withOpacity(0.05)]
                  : [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
            ),
            border: Border.all(
              color: isReady ? gradient[0].withOpacity(0.3) : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isReady ? gradient[0] : Colors.grey).withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - More compact
              _buildHeader(context),

              // Description - Smaller font and less spacing
              const SizedBox(height: 12),
              _buildDescription(context),

              // Features - More compact display
              if (features.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildFeatures(isDarkMode),
              ],

              // Action Button - Smaller and more compact
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
        // Smaller icon container
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: isReady
                ? LinearGradient(colors: gradient)
                : LinearGradient(colors: [Colors.grey, Colors.grey.shade600]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),

        // Title & Subtitle
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
                subtitle,
                style: TextStyle(
                  color: isReady ? gradient[0] : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Status Indicator - Smaller
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isReady ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady ? Icons.check_circle : Icons.access_time,
            size: 12,
            color: isReady ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isReady ? 'Ready' : 'Loading',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isReady ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      description,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFeatures(bool isDarkMode) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: features.take(3).map((feature) { // Limit to 3 features
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isReady ? gradient[0].withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isReady ? gradient[0].withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 12,
                color: isReady ? gradient[0] : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                feature,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isReady
                      ? (isDarkMode ? Colors.white70 : const Color(0xFF2C3E50))
                      : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isReady ? LinearGradient(colors: gradient) : null,
        borderRadius: BorderRadius.circular(10),
        color: !isReady ? Colors.grey : null,
      ),
      child: TextButton(
        onPressed: isReady ? onSelect : null,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select Method',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}