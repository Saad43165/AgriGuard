import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../Profile/presentation/Components/glass_card.dart';
import 'section_header.dart';
import 'action_item.dart';

class NextStepsCard extends StatelessWidget {
  const NextStepsCard({super.key});

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
            padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
            child: Column(
              children: [
                ActionItem(
                  icon: Icons.history_rounded,
                  title: 'Monitor Progress',
                  subtitle: 'Check back in 3-5 days',
                  onTap: () => HapticFeedback.lightImpact(),
                ),
                const SizedBox(height: AppMeasurements.smallPadding),
                ActionItem(
                  icon: Icons.local_pharmacy_rounded,
                  title: 'Purchase Treatment',
                  subtitle: 'Find recommended products',
                  onTap: () => HapticFeedback.lightImpact(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}