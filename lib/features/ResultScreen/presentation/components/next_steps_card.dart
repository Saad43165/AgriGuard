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
        subtitle: 'Check back in 3-5 days to track healing progress',
        color: Color(0xFF3B82F6),
      ),
      ActionItemData(
        icon: Icons.local_pharmacy_rounded,
        title: 'Get Treatment Products',
        subtitle: 'Find recommended products at your local store',
        color: Color(0xFF10B981),
      ),
      ActionItemData(
        icon: Icons.people_rounded,
        title: 'Consult Expert',
        subtitle: 'Contact a specialist if symptoms worsen',
        color: Color(0xFFF59E0B),
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Next Steps',
          icon: Icons.next_plan_rounded,
          subtitle: 'Recommended actions to take',
          iconColor: const Color(0xFF10B981),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                const Color(0xFF1E293B),
                const Color(0xFF0F172A),
              ]
                  : [
                Colors.white,
                const Color(0xFFF8FAFC),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: actionItems.isEmpty
              ? _buildEmptyState(context, isDark)
              : Column(
            children: List.generate(
              actionItems.length,
                  (index) => _buildActionItem(
                context: context,
                item: actionItems[index],
                index: index,
                isLast: index == actionItems.length - 1,
                isDark: isDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.1),
                  const Color(0xFF10B981).withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 48,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Next Steps Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required ActionItemData item,
    required int index,
    required bool isLast,
    required bool isDark,
  }) {
    final itemColor = item.color ?? const Color(0xFF10B981);

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
            width: 1.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.only(
            topLeft: index == 0 ? const Radius.circular(18) : Radius.zero,
            topRight: index == 0 ? const Radius.circular(18) : Radius.zero,
            bottomLeft: isLast ? const Radius.circular(18) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(18) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [itemColor, itemColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: itemColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: itemColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: itemColor,
                  ),
                ),
              ],
            ),
          ),
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
  final Color? color;

  const ActionItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.color,
  });
}