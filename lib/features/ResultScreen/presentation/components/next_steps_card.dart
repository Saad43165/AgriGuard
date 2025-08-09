import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../Profile/presentation/Components/glass_card.dart';
import 'section_header.dart';
import 'action_item.dart';

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
        const SizedBox(height: AppMeasurements.smallPadding),
        GlassCard(
          child: Padding(
            padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
            child: Column(
              children: [
                for (var i = 0; i < actionItems.length; i++) ...[
                  Semantics(
                    label: actionItems[i].title,
                    button: true,
                    enabled: actionItems[i].onTap != null,
                    child: ActionItem(
                      icon: actionItems[i].icon,
                      title: actionItems[i].title,
                      subtitle: actionItems[i].subtitle,
                      onTap: actionItems[i].onTap ?? () => HapticFeedback.lightImpact(),
                    ),
                  ),
                  if (i < actionItems.length - 1)
                    const SizedBox(height: AppMeasurements.smallPadding),
                ],
              ],
            ),
          ),
        ),
      ],
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