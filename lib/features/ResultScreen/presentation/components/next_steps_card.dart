import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/translation_service.dart';
import 'section_header.dart';

class NextStepsCard extends StatelessWidget {
  final List<ActionItemData> actionItems;

  const NextStepsCard({
    super.key,
    this.actionItems = const [
      ActionItemData(
        icon: Icons.history_rounded,
        titleKey: 'monitor_progress',
        subtitleKey: 'monitor_progress_desc',
        color: Color(0xFF3B82F6),
      ),
      ActionItemData(
        icon: Icons.local_pharmacy_rounded,
        titleKey: 'get_treatment',
        subtitleKey: 'get_treatment_desc',
        color: Color(0xFF10B981),
      ),
      ActionItemData(
        icon: Icons.people_rounded,
        titleKey: 'consult_expert',
        subtitleKey: 'consult_expert_desc',
        color: Color(0xFFF59E0B),
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final translation = Provider.of<TranslationService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: translation.get('next_steps'),
          icon: Icons.next_plan_rounded,
          subtitle: translation.get('recommended_actions'),
          iconColor: const Color(0xFF10B981),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
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
              ? _buildEmptyState(context, isDark, translation)
              : Column(
            children: List.generate(
              actionItems.length,
                  (index) => _buildActionItem(
                context: context,
                item: actionItems[index],
                index: index,
                isLast: index == actionItems.length - 1,
                isDark: isDark,
                translation: translation,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, TranslationService translation) {
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
            child: const Icon(
              Icons.info_outline_rounded,
              size: 48,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            translation.get('no_next_steps'),
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
    required TranslationService translation,
  }) {
    final itemColor = item.color ?? const Color(0xFF10B981);

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
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
                        translation.get(item.titleKey),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (item.subtitleKey.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          translation.get(item.subtitleKey),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
  final String titleKey;
  final String subtitleKey;
  final VoidCallback? onTap;
  final Color? color;

  const ActionItemData({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    this.onTap,
    this.color,
  });
}