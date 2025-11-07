import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/glass_card.dart';
import 'section_header.dart';

class RecommendationsCard extends StatelessWidget {
  final List<String> recommendations;

  const RecommendationsCard({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w500,
      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Treatment Recommendations',
          icon: Icons.medical_services_rounded,
        ),
        const SizedBox(height: AppMeasurements.smallPadding),
        GlassCard(
          child: _buildRecommendationsList(context, textStyle),
        ),
      ],
    );
  }

  Widget _buildRecommendationsList(BuildContext context, TextStyle? textStyle) {
    if (recommendations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No recommendations available',
          style: textStyle,
        ),
      );
    }

    return Column(
      children: List.generate(
        recommendations.length,
            (index) => _buildRecommendationItem(
          context: context,
          text: recommendations[index],
          textStyle: textStyle,
          isLast: index == recommendations.length - 1,
        ),
      ),
    );
  }

  Widget _buildRecommendationItem({
    required BuildContext context,
    required String text,
    required TextStyle? textStyle,
    required bool isLast,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIconContainer(context),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.2),
            theme.colorScheme.secondary.withOpacity(0.2),
          ],
        ),
      ),
      child: Icon(
        Icons.check_circle_rounded,
        color: theme.colorScheme.secondary,
        size: AppMeasurements.getResponsiveIconSizeSmall(context),
      ),
    );
  }
}