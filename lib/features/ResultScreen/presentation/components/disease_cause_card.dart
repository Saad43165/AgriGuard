// components/disease_causes_card.dart
import 'package:flutter/material.dart';

class DiseaseCausesCard extends StatelessWidget {
  final List<String> causes;

  const DiseaseCausesCard({
    super.key,
    required this.causes,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCausesCard(context);
  }

  Widget _buildCausesCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withOpacity(0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6750A4).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.science_rounded,
                    color: const Color(0xFF6750A4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Disease Causes & Factors',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Content
          causes.isEmpty
              ? _buildEmptyState(context)
              : _buildCausesList(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No disease analysis available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plant could not be identified or analysis failed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCausesList(BuildContext context) {
    return Column(
      children: List.generate(
        causes.length,
            (index) => _buildCauseItem(
          context: context,
          text: causes[index],
          index: index,
          isLast: index == causes.length - 1,
        ),
      ),
    );
  }

  Widget _buildCauseItem({
    required BuildContext context,
    required String text,
    required int index,
    required bool isLast,
  }) {
    final theme = Theme.of(context);

    // Clean up the text
    String cleanText = text.trim();
    if (cleanText.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with number
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6750A4).withOpacity(0.2),
                    const Color(0xFF6750A4).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF6750A4).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: const Color(0xFF6750A4),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Cause Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      height: 1.6,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  // Add small spacing between items
                  if (!isLast) const SizedBox(height: 8),
                ],
              ),
            ),
            // Info icon
            const SizedBox(width: 8),
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: const Color(0xFF6750A4).withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}