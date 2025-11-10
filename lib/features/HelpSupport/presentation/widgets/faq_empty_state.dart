import 'package:flutter/material.dart';

import '../../../../core/constants/app_measurements.dart';
import '../../../../core/widgets/glass_card.dart';

class FaqEmptyState extends StatelessWidget {
  const FaqEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final double itemSpacing = AppMeasurements.getResponsivePadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(itemSpacing),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Center(
          child: GlassCard(
            child: Padding(
              padding: EdgeInsets.all(itemSpacing * 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  SizedBox(height: itemSpacing),
                  Text(
                    'No FAQs found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: itemSpacing / 2),
                  Text(
                    'Try adjusting your search or category filter',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}