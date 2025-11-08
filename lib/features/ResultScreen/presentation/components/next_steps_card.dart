import 'package:flutter/material.dart';
import 'section_header.dart';

class NextStepsCard extends StatelessWidget {
  final List<ActionItemData> actionItems;

  const NextStepsCard({
    super.key,
    this.actionItems = const [
      ActionItemData(
        icon: Icons.history_rounded,
        title: 'Monitor Progress',
        subtitle: 'Check back in 3-5 days',
      ),
      ActionItemData(
        icon: Icons.local_pharmacy_rounded,
        title: 'Purchase Treatment',
        subtitle: 'Find recommended products',
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Next Steps',
          icon: Icons.next_plan_rounded,
        ),
        const SizedBox(height: 12),
        _buildNextStepsCard(context),
      ],
    );
  }

  Widget _buildNextStepsCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withOpacity(0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
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
      child: actionItems.isEmpty
          ? _buildEmptyState(context)
          : _buildActionItemsList(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No next steps available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItemsList(BuildContext context) {
    return Column(
      children: List.generate(
        actionItems.length,
            (index) => _buildActionItem(
          context: context,
          item: actionItems[index],
          index: index,
          isLast: index == actionItems.length - 1,
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required ActionItemData item,
    required int index,
    required bool isLast,
  }) {
    final theme = Theme.of(context);

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
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const ActionItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}